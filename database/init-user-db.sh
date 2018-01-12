#!/bin/bash
set -e

createdb -O sshobs --no-password dbname
createdb ssh_observatory
psql -U sshobs -d ssh_observatory < /app/schema.sql