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