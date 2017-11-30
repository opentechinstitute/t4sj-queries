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