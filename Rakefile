require 'rake'
require 'rspec'
require 'rspec/core/rake_task'
require 'bundler/setup'
require 'sinatra/activerecord/rake'
require 'ssh_scan'

namespace :db do
  task :load_config do
    require "./lib/ssh_scan_api/api"
  end
end

task :default => :spec

desc "Run all specs in spec directory"
RSpec::Core::RakeTask.new(:spec)