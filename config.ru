require 'rubygems'
require 'bundler'
Bundler.require

require './app.rb'
Rack::Handler.default.run(App, :Port => 8000, :Host => "127.0.0.1")