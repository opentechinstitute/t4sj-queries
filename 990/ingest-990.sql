DROP TABLE IF EXISTS irs990;

CREATE UNLOGGED TABLE irs990 (
    id SERIAL PRIMARY KEY,
    DLN VARCHAR,
    EIN VARCHAR,
    FormType VARCHAR,
    LastUpdated VARCHAR,
    ObjectId VARCHAR,
    OrganizationName VARCHAR,
    SubmittedOn VARCHAR,
    TaxPeriod VARCHAR,
    URL VARCHAR,
    value VARCHAR,
    version VARCHAR,
    xpath VARCHAR,
    variable VARCHAR,
    form VARCHAR,
    part VARCHAR,
    scope VARCHAR,
    location VARCHAR,
    analyst VARCHAR);

COPY irs990 (
    DLN,
    EIN,
    FormType,
    LastUpdated,
    ObjectId,
    OrganizationName,
    SubmittedOn,
    TaxPeriod,
    URL,
    value,
    version,
    xpath,
    variable,
    form,
    part,
    scope,
    location,
    analyst)
FROM PROGRAM 'gunzip -c /990/part-00*-850e82e0-c0f4-4157-892e-d7937a1b0342-c000.csv.gz'
WITH (
    FORMAT csv,
    ESCAPE '\'
);

ALTER TABLE irs990 SET LOGGED;


