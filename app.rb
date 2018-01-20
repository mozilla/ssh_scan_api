require 'sinatra'
require 'sinatra/activerecord'
require 'securerandom'

enable :logging
set :database, {adapter: "sqlite3", database: "foo.sqlite3"}
set :bind, '127.0.0.1'
set :server, 'thin'
set :logger, Logger.new(STDOUT)

class Scan < ActiveRecord::Base
  validates_presence_of :target
  validates_presence_of :port
  validates_presence_of :state
end

class App < Sinatra::Base
  before do
    content_type :json
  end

  get '/queue' do
    Scan.new do |s|
      s.scan_id = SecureRandom.uuid
      s.target = params["target"]
      s.port = 22
      s.state = "QUEUED"
      s.save
    end
  end

  get '/batch_queue' do
    Scan.new do |s|
      s.scan_id = SecureRandom.uuid
      s.target = params["target"]
      s.port = 22
      s.state = "BATCH_QUEUED"
      s.save
    end
  end

  get '/run/:scan_id/?' do
    @scan = Scan.find_by(scan_id: params[:scan_id])
    @scan.state = "RUNNING"
    @scan.save
    @scan.to_json
  end

  get '/error/:scan_id/?' do
    @scan = Scan.find_by(scan_id: params[:scan_id])
    @scan.state = "ERRORED"
    @scan.save
    @scan.to_json
  end

  get '/complete/:scan_id/?' do
    @scan = Scan.find_by(scan_id: params[:scan_id])
    @scan.state = "COMPLETED"
    @scan.save
    @scan.to_json
  end

  get '/scans' do
    @scans = Scan.all
    @scans.to_json
  end

  get '/scans/:scan_id/?' do
    @scan = Scan.find_by(scan_id: params[:scan_id])
    @scan.to_json
  end
end