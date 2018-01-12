#!/bin/bash
set -e

createuser sshobs --no-password
createdb -O ssh_observatory
psql -U sshobs -d ssh_observatory < /app/schema.sql