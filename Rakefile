require 'rubygems'
require 'rake'
require 'rubygems/package_task'
require 'rspec'
require 'rspec/core'
require 'rspec/core/rake_task'
require 'bundler/setup'
require "sinatra/activerecord/rake"

namespace :db do
  task :load_config do
    require File.join(File.dirname(__FILE__), "./lib/ssh_scan_api/api")
  end
end

$:.unshift File.join(File.dirname(__FILE__), "lib")

require 'ssh_scan'

task :default => :spec

desc "Run all specs in spec directory"
RSpec::Core::RakeTask.new(:spec)