-- Defines postgres bootstrap

--Create the 'sshobs' postgres user account
CREATE ROLE sshobs WITH LOGIN PASSWORD 'auserpassword'; -- need to parameterize the password, so it's not baked into the schema bootstrap
ALTER ROLE sshobs CREATEDB; 

-- Create the ssh_observatory database
CREATE DATABASE ssh_observatory;

-- Give the sshobser user full access to the ssh_observatory database
GRANT ALL PRIVILEGES ON DATABASE ssh_observatory TO sshobs;

-- Define the scan table
CREATE TABLE IF NOT EXISTS scans (
  id SERIAL PRIMARY KEY,
  target VARCHAR(255) NOT NULL,
  port SMALLINT NOT NULL,
  state VARCHAR(255) NOT NULL,
  uuid VARCHAR(255) NULL,
  worker_id VARCHAR(255) NULL,
  scan JSONB NULL
);