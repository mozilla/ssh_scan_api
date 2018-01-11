-- Define the scan table
CREATE TABLE IF NOT EXISTS scans (
  id SERIAL PRIMARY KEY,
  timestamp timestamp default current_timestamp
  target VARCHAR(255) NOT NULL,
  port SMALLINT NOT NULL,
  state VARCHAR(255) NOT NULL,
  uuid VARCHAR(255) NULL,
  worker_id VARCHAR(255) NULL,
  scan JSONB NULL
);