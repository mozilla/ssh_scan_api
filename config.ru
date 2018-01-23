require 'rubygems'
require 'bundler'
Bundler.require

require './lib/ssh_scan_api/api.rb'
Rack::Handler.default.run(SSHScan::Api, :Port => 8000, :Host => "127.0.0.1")