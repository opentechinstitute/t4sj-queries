-- queries for Jobs data

/*
FIELDS
jobkey      | character varying(20)  | not null  | extended |              | 
 city        | character varying(100) |           | extended |              | 
 country     | character varying(2)   |           | extended |              | 
 state       | character varying(2)   |           | extended |              | 
 company     | character varying(100) |           | extended |              | 
 date_posted | date                   |           | plain    |              | 
 jobtitle    | character varying(400) |           | extended |              | 
 language    | character varying(2)   |           | extended |              | 
 snippet     | character varying(400) |           | extended |              | 
 source      | character varying(300) |           | extended |              | 
 url         | character varying(500) |           | extended |              | 
 fulldesc    | text                   |           | extended |              | 

*/

-- most common words in descriptions, mapped to lexemes, topic
COPY (SELECT MAX(token), topic, count(*)
FROM t4sjtermresults, lateral ( SELECT * FROM ts_debug('english', fulldesc)) x 
WHERE x.alias in ('asciiword', 'word')
AND array_length(lexemes, 1) > 0
GROUP BY lexemes, topic) TO STDOUT WITH (FORMAT CSV, header);

-- most common words in titles, mapped to lexemes, topic
COPY (SELECT MAX(token), topic, count(*)
FROM t4sjtermresults, lateral ( SELECT * FROM ts_debug('english', jobtitle)) x 
WHERE x.alias in ('asciiword', 'word')
AND array_length(lexemes, 1) > 0
GROUP BY lexemes, topic) TO STDOUT WITH (FORMAT CSV, header);

-- Company list, topic
COPY(SELECT company, topic, count(company) from t4sjtermresults GROUP by company, topic) TO STDOUT WITH (FORMAT CSV, header);

-- distribution of jobs by place, topic
COPY(SELECT city, state, topic, count(jobtitle) from t4sjtermresults GROUP by city, state, topic) TO STDOUT WITH (FORMAT CSV, header);

-- Top 10 most common variable names
SELECT 
    matchedterm,
    num
FROM (
    SELECT 
        matchedterm,
        count(*) AS num 
    FROM indeed 
    GROUP BY matchedterm) x
ORDER BY num DESC
LIMIT 50; 


