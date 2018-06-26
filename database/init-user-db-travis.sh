#!/bin/bash
set -e

createuser sshobs --no-password --superuser
bundle exec rake db:drop && rake db:create && rake db:migrate