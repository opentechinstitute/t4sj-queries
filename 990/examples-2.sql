-- turning this into a repo
-- make .sql files per intelligentily named query
-- add comments etc
-- then the .sql files are executable & shareable

-- UTILITIES

\d -- list tables
\di -- list indicies
\d+ tablename -- list fields in tables
\q -- quit

-- The create index statements I used. The full-text index is definitely the
-- slowest to create.
-- CREATE INDEX on t4sjorgs USING btree(xpath);
CREATE INDEX on t4sjorgs USING btree(ein);
CREATE INDEX on t4sjorgs USING btree(organizationname);
CREATE INDEX on t4sjorgs USING btree(variable);
CREATE INDEX on t4sjorgs USING btree(location);
CREATE INDEX on t4sjorgs USING gin(to_tsvector('english', value));


-- Top 10 most common variable names
SELECT 
    variable,
    num 
FROM (
    SELECT 
        variable,
        count(*) AS num 
    FROM t4sjtermresultsnov 
    GROUP BY variable) x
ORDER BY num DESC
LIMIT 10; 


COPY ( SELECT 
    organizationname,
    num 
FROM (
    SELECT 
        organizationname,
        count(*) AS num 
    FROM t4sjtermresults 
    GROUP BY organizationname) x
ORDER BY num DESC ) TO STDOUT WITH (FORMAT CSV, header); 

-- Top 50 most common 
-- * words from values split by whitespace
-- * where the word is all letters and at least 3 letters long
-- * where the variable name contains DESC
SELECT 
    term,
    num
FROM (
    SELECT 
        term,
        count(*) AS num 
    FROM (
        SELECT 
            regexp_split_to_table(value, E'\\s+') AS term 
        FROM irs990
        WHERE 
            variable LIKE '%DESC%') sub
    WHERE term ~ '[:alpha:]{3,}'
    GROUP BY term) sub
ORDER BY num DESC
LIMIT 50;

-- Organization, variable, and location where the value contains the word 'education'
SELECT organizationname, variable, location 
FROM irs990 
WHERE to_tsvector('english', value) @@ to_tsquery('english', 'education');

SELECT *
FROM irs990 
WHERE ein = '131684331';

-- Itemized count of organizations mentioning 'education', 'poverty', or
-- 'technology' in their ACTIVIDESCRI variable's value
SELECT
    t.topic,
    count(irs990) 
FROM (
    VALUES 
        ('education'),
        ('technology')) t (topic) 
JOIN irs990 
ON to_tsvector('english', irs990.value) @@ to_tsquery('english', t.topic)
WHERE irs990.variable = 'ACTIVIDESCRI'
GROUP BY t.topic;

-- Or get all rows by omitting the group by clause
-- 'technology' in their ACTIVIDESCRI variable's value
SELECT DISTINCT 
    t.topic,
    irs990.variable
FROM (
    VALUES
    ('civic'),
    ('technology')) t (topic)
JOIN irs990
ON to_tsvector('english', irs990.value) @@ to_tsquery('english', t.topic);

-- orgnames, variable, topic word

SELECT DISTINCT 
    t.topic,
    irs990.variable,
    irs990.organizationname,
    irs990.value
FROM (
    VALUES
    ('access <-> to <-> tech')) t (topic)
JOIN irs990
ON to_tsvector('english', irs990.value) @@ to_tsquery('english', t.topic);

SELECT DISTINCT 
    t.topic,
    irs990.variable,
    irs990.organizationname
FROM (
    VALUES
    ('social <-> justice')) t (topic)
JOIN irs990
ON to_tsvector('english', irs990.value) @@ to_tsquery('english', t.topic);


-- Get a list of all organization names for each EIN that has more than one
SELECT * 
FROM (
    SELECT 
        ein,
        count(DISTINCT organizationname) AS num,
        array_agg(DISTINCT organizationname) AS names 
    FROM irs990 
    GROUP BY ein) s 
WHERE num > 1 LIMIT 10;

-- Copy out an arbitrary SELECT query to CSV (replace STDOUT with a path in
-- 'single quotes' to write to a file)
COPY (SELECT ein, organizationname, xpath, value FROM irs990 LIMIT 100) TO STDOUT WITH (FORMAT CSV, header);

COPY (SELECT *
FROM irs990 
WHERE ein = '131684331') TO STDOUT WITH (FORMAT CSV, header);


-- make a table
CREATE TABLE table_name
    AS query;

-- INSERT INTO A TABLE a smaller query


/*
*/

--VISUALIZATIONS to create base queries for:
 -- org names list --> compare with org list SEE: orgs_terms_rank.csv

-- REVENUE BY TERM
--- distinct orgs from t4sjtermresults

SELECT DISTINCT 
    ein
    FROM t4sjtermresultsnov;

--- get all variables from irs990 for disctinct orgs

CREATE TABLE t4sjorgs AS 
    SELECT irs990.* 
    FROM irs990, (SELECT DISTINCT ein FROM t4sjtermresults) eins
    WHERE irs990.ein = eins.ein;




--- term, tot_rev, tot_contributions, taxperiod summaries

COPY (SELECT
 t4sjtermresults.topic,
 t4sjorgs.taxperiod,
 t4sjorgs.variable,
 SUM(t4sjorgs.value :: REAL)
FROM t4sjorgs, t4sjtermresults
WHERE t4sjorgs.variable in ('CYTYTOTOTREV','CYCYCOCONGRA') 
    AND t4sjorgs.ein = t4sjtermresults.ein 
    AND t4sjorgs.taxperiod = t4sjtermresults.taxperiod
    GROUP BY t4sjtermresults.topic, t4sjorgs.taxperiod, t4sjorgs.variable) TO STDOUT WITH (FORMAT CSV, header);

--- taxperiod, tot_rev, tot_contributions summaries

COPY (SELECT
 t4sjorgs.taxperiod,
 t4sjorgs.variable,
 SUM(t4sjorgs.value :: REAL)
FROM t4sjorgs, t4sjtermresults
WHERE t4sjorgs.variable in ('CYTYTOTOTREV','CYCYCOCONGRA') 
    AND t4sjorgs.ein = t4sjtermresults.ein 
    AND t4sjorgs.taxperiod = t4sjtermresults.taxperiod
    GROUP BY t4sjorgs.taxperiod, t4sjorgs.variable) TO STDOUT WITH (FORMAT CSV, header);


/*
*/

-- org names // missions word cloud

COPY (SELECT MAX(token), count(*)
FROM t4sjorgs, lateral ( SELECT * FROM ts_debug('english', value)) x 
WHERE x.alias in ('asciiword', 'word')
AND t4sjorgs.variable = 'ACTIMISSDESC'
AND array_length(lexemes, 1) > 0
GROUP BY lexemes) TO STDOUT WITH (FORMAT CSV, header);
--LIMIT 50;

-- org names, by topic // missions word cloud

CREATE TABLE topicmissionyear AS SELECT MAX(token), count(*), t4sjtermresults.topic, t4sjtermresults.organizationname, t4sjtermresults.formtype, substring (t4sjorgs.taxperiod for 4) as taxyear
FROM t4sjorgs, t4sjtermresults, lateral ( SELECT * FROM ts_debug('english', t4sjorgs.value)) x 
WHERE x.alias in ('asciiword', 'word')
AND t4sjorgs.variable = 'ACTIMISSDESC'
AND array_length(lexemes, 1) > 0
AND t4sjorgs.ein = t4sjtermresults.ein
GROUP BY lexemes, topic, taxyear, organizationname, formtype;
--LIMIT 50;

-- number of employees & volunteers

--- ilike == ignore case, find the field name for volunteers
SELECT * FROM t4sjorgs WHERE organizationname ILIKE 'mozilla%' AND variable ILIKE '%vol%';

COPY (SELECT ein, array_agg(organizationname), array_agg(value), taxperiod
FROM t4sjorgs
WHERE variable = 'VOLUNTEERSOL'
GROUP BY ein, taxperiod) TO STDOUT WITH (FORMAT CSV, header);

COPY (SELECT ein, array_agg(organizationname), array_agg(value), taxperiod
FROM t4sjorgs
WHERE variable = 'NUMBEREMPLOY'
GROUP BY ein, taxperiod) TO STDOUT WITH (FORMAT CSV, header);


-- count of formtypes
SELECT count(DISTINCT ein), formtype
FROM t4sjorgs
GROUP BY formtype;

/*
RESULTS

count | formtype 
-------+----------
  1254 | 990
   409 | 990EZ
   292 | 990PF

*/


-- org - funders network map

CREATE TABLE fundergranteenetwork AS SELECT t.organizationname as funder, t.ein as funderein, t.value as grantee, i.ein as granteeein
FROM t4sjorgs t JOIN (select ein, max(organizationname) as organizationname from ein_organization group by ein) i on (i.organizationname = t.value)
WHERE t.variable = 'SIGOCRBNBNLI1'
AND t.formtype = '990PF';


\COPY (SELECT * FROM fundergranteenetwork) TO 'fundergranteenetwork.csv' WITH (FORMAT CSV, header);

-- time series!

-- R can read postgres -- RPostgreSQL (CRAN)


-- term, org, field, form, tax
SELECT topic, organizationname, variable, formtype, substring (t4sjorgs.taxperiod for 4) as taxyear FROM t4sjtermresults;


/*
Other questions
- Noise in the data
- potential double filings affecting overall numbers
- potential missing data --> e.g. is our data set smaller than it should be


*/