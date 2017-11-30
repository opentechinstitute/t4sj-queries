-- Top 10 most common variable names
SELECT 
    variable,
    num 
FROM (
    SELECT 
        variable,
        count(*) AS num 
    FROM irs990 
    GROUP BY variable)
ORDER BY num DESC
LIMIT 10; 