#!/bin/bash
set -e

createuser -O sshobs --no-password
createdb ssh_observatory
psql -U sshobs -d ssh_observatory < ./database/schema.sql