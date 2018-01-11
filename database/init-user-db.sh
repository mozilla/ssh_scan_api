#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "sshobs" <<-EOSQL
	CREATE DATABASE ssh_observatory;
	GRANT ALL PRIVILEGES ON DATABASE ssh_observatory TO sshobs;
EOSQL