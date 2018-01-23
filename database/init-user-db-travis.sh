#!/bin/bash
set -e

createuser sshobs --no-password --superuser
rake db:drop && rake db:create && rake db:migrate