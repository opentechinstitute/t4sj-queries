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