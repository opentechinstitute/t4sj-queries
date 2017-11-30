-- Copy out an arbitrary SELECT query to CSV (replace STDOUT with a path in
-- 'single quotes' to write to a file)
COPY (SELECT ein, organizationname, xpath, value FROM irs990 LIMIT 100) TO STDOUT WITH (FORMAT CSV, header);


-- make a table
CREATE TABLE table_name
    AS query;