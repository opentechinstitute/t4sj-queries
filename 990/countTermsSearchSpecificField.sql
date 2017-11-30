-- Or get all rows by omitting the group by clause
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