#!/bin/bash
set -e

createuser sshobs --no-password
createdb -O sshobs dbname
psql -U sshobs -d ssh_observatory < /app/schema.sql