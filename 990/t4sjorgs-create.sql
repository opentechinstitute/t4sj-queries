CREATE TABLE t4sjorgs AS 
    SELECT irs990.* 
    FROM irs990, (SELECT DISTINCT ein FROM t4sjtermresultsnov) eins
    WHERE irs990.ein = eins.ein;