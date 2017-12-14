CREATE TABLE t4sjtermresultsNov
    AS
SELECT DISTINCT 
    t.category,
    irs990.organizationname,
    irs990.ein,
    irs990.location,
    irs990.part,
    irs990.taxperiod,
    irs990.formtype,
    irs990.url,
    irs990.variable,
    irs990.value
FROM t4sjtermscats t
JOIN irs990
ON to_tsvector('english', irs990.value) @@ to_tsquery('english', t.searchterm);


CREATE TABLE t4sjtermresultsNov2
    AS
SELECT 
    t.category,
    irs990.organizationname,
    irs990.ein,
    irs990.location,
    irs990.part,
    irs990.taxperiod,
    irs990.formtype,
    irs990.url,
    irs990.variable,
    irs990.value
FROM t4sjtermscats t
JOIN irs990
ON to_tsvector('english', irs990.value) @@ to_tsquery('english', t.searchterm);



-----------------------

CREATE TABLE t4sjtermresultsNov3
    AS
SELECT DISTINCT 
    t.category,
    t.terms,
    irs990.organizationname,
    irs990.ein,
    irs990.location,
    irs990.part,
    irs990.taxperiod,
    irs990.formtype,
    irs990.url,
    irs990.variable,
    irs990.value
FROM (select category, array_agg(to_tsquery('english', searchterm)) as text_query, array_agg(searchterm) as terms from t4sjtermscats GROUP BY category) t
JOIN irs990
ON to_tsvector('english', irs990.value) @@ ANY(t.text_query);


