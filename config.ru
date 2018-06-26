require 'rubygems'
require 'bundler'
Bundler.require

require './lib/ssh_scan_api/api.rb'
Rack::Handler.default.run(SSHScan::Api::Api)