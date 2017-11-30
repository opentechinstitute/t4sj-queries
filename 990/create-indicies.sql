-- The create index statements I used. The full-text index is definitely the
-- slowest to create.
CREATE INDEX on irs990 USING btree(EIN);
CREATE INDEX on irs990 USING btree(OrganizationName);
CREATE INDEX on irs990 USING btree(xpath);
CREATE INDEX on irs990 USING btree(variable);
CREATE INDEX on irs990 USING btree(location);
CREATE INDEX on irs990 USING gin(to_tsvector('english', value));