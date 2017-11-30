CREATE TABLE t4sjtermresultsNov
    AS
SELECT DISTINCT 
    t.category,
    indeed.jobkey,
    indeed.city,
    indeed.country,
    indeed.state,
    indeed.company,
    indeed.date_posted,
    indeed.jobtitle,
    indeed.language,
    indeed.snippet,
    indeed.source,
    indeed.url,
    indeed.fulldesc,
    indeed.matchedterm
FROM t4sjtermscats t
JOIN indeed
ON to_tsvector('english', indeed.fulldesc) @@ to_tsquery('english', t.searchterm);