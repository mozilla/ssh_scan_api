require 'sinatra/activerecord'

class SSHScan::Scan < ActiveRecord::Base
  validates_presence_of :target
  validates_presence_of :port
  validates_presence_of :state
end