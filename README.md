asdfasdfas# ssh_scan_api

A web api to scale ssh_scan operations

## Setup

To install and run as a gem, type:

```bash
gem install ssh_scan_api
ssh_scan_api
```

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

## Rubies Supported

This project is integrated with [travis-ci](http://about.travis-ci.org/) and is regularly tested to work with the following rubies:

* [ruby-head](https://github.com/ruby/ruby)
* [2.3.0](https://github.com/ruby/ruby/tree/ruby_2_1)
* [2.2.0](https://github.com/ruby/ruby/tree/ruby_2_1)
* [2.1.3](https://github.com/ruby/ruby/tree/ruby_2_1)
* [2.1.0](https://github.com/ruby/ruby/tree/ruby_2_1)
* [2.0.0](https://github.com/ruby/ruby/tree/ruby_2_0_0)

To checkout the current build status for these rubies, click [here](https://travis-ci.org/#!/mozilla/ssh_scan).

## Contributing

If you are interested in contributing to this project, please see [CONTRIBUTING.md](https://github.com/mozilla/ssh_scan/blob/master/CONTRIBUTING.md).

## Credits

**Sources of Inspiration for ssh_scan**

- [**Mozilla OpenSSH Security Guide**](https://wiki.mozilla.org/Security/Guidelines/OpenSSH) - For providing a sane baseline policy recommendation for SSH configuration parameters (eg. Ciphers, MACs, and KexAlgos).
