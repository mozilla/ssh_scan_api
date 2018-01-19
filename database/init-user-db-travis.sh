#!/bin/bash
set -e

createuser sshobs --no-password
createdb -O sshobs ssh_observatory
psql -U sshobs -d ssh_observatory < ./database/schema.sql