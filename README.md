# WARNING Deprecated - please use [ssh_scan](https://github.com/mozilla/ssh_scan) from command-line 

# ssh_scan_api

[![Build Status](https://secure.travis-ci.org/mozilla/ssh_scan_api.png)](http://travis-ci.org/mozilla/ssh_scan_api)
[![Code Climate](https://codeclimate.com/github/mozilla/ssh_scan_api.png)](https://codeclimate.com/github/mozilla/ssh_scan_api)
[![Gem Version](https://badge.fury.io/rb/ssh_scan.svg)](https://badge.fury.io/rb/ssh_scan_api)
[![Join the chat at https://gitter.im/mozilla-ssh_scan/Lobby](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/mozilla-ssh_scan/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
[![Coverage Status](https://coveralls.io/repos/github/mozilla/ssh_scan_api/badge.svg?branch=master)](https://coveralls.io/github/mozilla/ssh_scan_api?branch=master)

A web api to scale ssh_scan operations

## Setup

To install and run from source, type:

```bash
# clone repo
git clone https://github.com/mozilla/ssh_scan_api.git
cd ssh_scan_api

# install rvm,
# you might have to provide root to install missing packages
gpg2 --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
curl -sSL https://get.rvm.io | bash -s stable

# install Ruby 2.3.1 with rvm,
# again, you might have to install missing devel packages
rvm install 2.3.1
rvm use 2.3.1

# resolve dependencies
gem install bundler
bundle install

./bin/ssh_scan_api
```

## ssh_scan as a command-line tool?

This project is focused on providing ssh_scan as a service/API.

If you would like to run ssh_scan from command-line, checkout the [ssh_scan](https://github.com/mozilla/ssh_scan) project.

## Rubies Supported

This project is integrated with [travis-ci](http://about.travis-ci.org/) and is regularly tested to work with multiple rubies.

To checkout the current build status for these rubies, click [here](https://travis-ci.org/#!/mozilla/ssh_scan_api).

## Contributing

If you are interested in contributing to this project, please see [CONTRIBUTING.md](https://github.com/mozilla/ssh_scan/blob/master/CONTRIBUTING.md).

## Credits

**Sources of Inspiration for ssh_scan**

- [**Mozilla OpenSSH Security Guide**](https://wiki.mozilla.org/Security/Guidelines/OpenSSH) - For providing a sane baseline policy recommendation for SSH configuration parameters (eg. Ciphers, MACs, and KexAlgos).
