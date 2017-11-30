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