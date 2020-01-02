use rayon::prelude::*;
use rust_stemmers::{Algorithm, Stemmer};
use std::collections::{BTreeSet, HashMap};
use std::io::Read;
use structopt::StructOpt;
use walkdir::{DirEntry, WalkDir};

#[derive(Debug, StructOpt)]
struct Args {
    /// Directories to ingest - these will be traversed recursively.
    #[structopt(default_value = "data/")]
    paths: Vec<String>,
    /// Path to CSV file defining categories
    #[structopt(long, default_value = "data/terms.csv")]
    category_definitions: String,
}

/// Inspects a directory entry to see if it is a regular file and
/// the filename looks like a 990 data chunk.
fn looks_like_part(entry: &DirEntry) -> bool {
    let is_file = entry.metadata().ok().map_or(false, |md| md.is_file());
    let file_name = entry.path().file_name().and_then(|name| name.to_str());
    let name_follows_pattern = file_name.map_or(false, |name| {
        name.starts_with("part-") && (name.ends_with(".csv") || name.ends_with(".csv.gz"))
    });
    is_file && name_follows_pattern
}

/// Holds a stemmer and the label table to encapsulate identifying
/// which labels apply to a record.
#[derive(Clone, Copy)]
struct Analyzer<'a> {
    stemmer: &'a Stemmer,
    categories: &'a HashMap<&'a str, Vec<&'a [String]>>,
}

impl<'a> Analyzer<'a> {
    /// Creates an analyzer that reuses an existing stemmer and label table
    fn new(stemmer: &'a Stemmer, categories: &'a HashMap<&'a str, Vec<&'a [String]>>) -> Self {
        Self {
            stemmer,
            categories,
        }
    }
    /// Find the labels that apply to a text chunk.
    fn analyze(&self, text: &str) -> Vec<&'a str> {
        fn match_phrases(text: &[String], phrases: &[&[String]]) -> bool {
            (0..text.len()).any(|i| phrases.iter().any(|ph| text[i..].starts_with(ph)))
        }
        let stemmed_text: Vec<String> = text
            .split_whitespace()
            .map(|s| self.stemmer.stem(&s.to_lowercase()).to_string())
            .collect();
        self.categories
            .iter()
            .filter_map(|(label, phrases)| {
                if match_phrases(&stemmed_text, phrases) {
                    Some(*label)
                } else {
                    None
                }
            })
            .collect()
    }
}

/// Read category definitions from a header-less CSV file.
/// *Column 0* is expected to be a phrase using the `<->`
/// direct-follow operator from Postgres text search
/// (https://www.postgresql.org/docs/10/functions-textsearch.html)
/// *Column 1* is the label to apply to records that match the phrase
/// after stemming.
fn load_categories(stemmer: &Stemmer, input: impl Read) -> Vec<(String, Vec<String>)> {
    let mut reader = csv::ReaderBuilder::new()
        .has_headers(false)
        .from_reader(input);
    reader
        .records()
        .filter_map(Result::ok)
        .map(|rec| {
            let stemmed_phrase: Vec<String> = rec
                .get(0)
                .map(|field| {
                    field
                        .split(" <-> ")
                        .map(|s| {
                            let lower = s.to_lowercase();
                            stemmer.stem(&lower).to_string()
                        })
                        .collect()
                })
                .unwrap();
            let label = rec.get(1).unwrap().to_string();
            (label, stemmed_phrase)
        })
        .collect()
}

/// Combines categories with the same label, allowing us
/// to avoid redundantly checking multiple terms for the same label.
fn index_categories(categories: &[(String, Vec<String>)]) -> HashMap<&str, Vec<&[String]>> {
    let mut result: HashMap<&str, Vec<&[String]>> = HashMap::new();
    for (label, phrase) in categories {
        result.entry(label).or_default().push(phrase);
    }
    result
}

fn main() {
    let args = Args::from_args();
    let all_paths = (args.paths.iter())
        .flat_map(WalkDir::new)
        .filter_map(Result::ok)
        .filter(|entry| looks_like_part(entry));
    let stemmer = Stemmer::create(Algorithm::English);
    let categories_file = std::fs::File::open(&args.category_definitions).unwrap();
    let categories = load_categories(&stemmer, categories_file);
    let category_index = index_categories(&categories);
    let analyzer = Analyzer::new(&stemmer, &category_index);
    type Report<'a> = HashMap<String, BTreeSet<&'a str>>;
    let result: Report = all_paths
        .flat_map(|entry| {
            let source = std::io::BufReader::new(std::fs::File::open(entry.path()).unwrap());
            let source: Box<dyn Read + Send> =
                if entry.path().extension() == Some(std::ffi::OsStr::new("gz")) {
                    Box::new(flate2::read::GzDecoder::new(source))
                } else {
                    Box::new(source)
                };
            let reader = csv::ReaderBuilder::new()
                .has_headers(false)
                .escape(Some(b'\\'))
                .from_reader(source);
            reader.into_records().filter_map(Result::ok)
        })
        .par_bridge()
        .filter_map(|rec| {
            let ein = rec.get(1).unwrap();
            let value = rec.get(9).unwrap();
            let labels = analyzer.analyze(value);
            if labels.is_empty() {
                None
            } else {
                Some((ein.to_string(), labels))
            }
        })
        .fold::<Report, _, _>(Report::new, |mut map, (ein, labels)| {
            map.entry(ein).or_default().extend(labels);
            map
        })
        .reduce(HashMap::new, |mut map, part| {
            for (ein, labels) in part {
                map.entry(ein).or_default().extend(labels);
            }
            map
        });
    let mut writer = csv::WriterBuilder::new()
        .flexible(true)
        .from_writer(std::io::stdout());
    for (ein, labels) in &result {
        let iter =
            std::iter::Iterator::chain(std::iter::once(ein.as_str()), labels.iter().cloned());
        writer.write_record(iter).unwrap();
    }
}
