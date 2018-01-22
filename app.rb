require 'sinatra'
require 'sinatra/activerecord'
require 'sinatra/namespace'
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
  register Sinatra::Namespace

  before do
    content_type :json
  end

  namespace "/api/v1" do
    post '/scan' do
      scan = Scan.new do |s|
        s.scan_id = SecureRandom.uuid
        s.target = params["target"]
        s.port = 22
        s.state = "QUEUED"
        s.save
      end

      {"uuid": scan.scan_id}.to_json
    end

    get '/work' do
      worker_id = params[:worker_id]

      scan = Scan.find_by("state": "QUEUED")

      if scan.nil?
        return {"work" => false}.to_json
      else
        scan.state = "RUNNING"
        scan.save

        return {
          "work" => {
            "uuid" => scan.scan_id,
            "target" => scan.target,
            "port" => scan.port 
          }
        }.to_json
      end
    end

    post '/work/results/:worker_id/:uuid' do
      worker_id = params['worker_id']
      uuid = params['uuid']
      result = JSON.parse(request.body.first).first

      scan = Scan.find_by("scan_id": uuid)
      scan.worker_id = worker_id
      scan.state = "COMPLETED"
      scan.scan = result.to_json
      scan.save
    end

    get '/scan/results' do
      uuid = params[:uuid]

      # If we don't get a uuid, we don't know what scan to pick up
      return {"error" => "no uuid specified"}.to_json if uuid.nil? || uuid.empty?

      scan = Scan.find_by("scan_id": uuid)

      if scan.nil?
        return {"scan" => "UNKNOWN"}.to_json
      end

      case scan.state
      when "QUEUED"
        return {"status" => "QUEUED"}.to_json
      when "ERRORED"
        return {"status" => "ERRORED"}.to_json
      when "RUNNNING"
        return {"status" => "RUNNNING"}.to_json
      when "COMPLETED"
        return scan.scan
      else
        return {"scan" => "UNKNOWN"}.to_json
      end
    end

    # get '/scans' do
    #   @scans = Scan.all
    #   @scans.to_json
    # end

    # get '/scans/:scan_id/?' do
    #   @scan = Scan.find_by(scan_id: params[:scan_id])
    #   @scan.to_json
    # end
  end

end