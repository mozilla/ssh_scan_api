require 'spec_helper'
require 'ssh_scan_api'
require 'rack/test'
require 'json'

require './lib/ssh_scan_api/api.rb'

describe SSHScan::Api::Api do
  include Rack::Test::Methods

  def app
    ENV['SSHSCAN_API_HOST'] = '127.0.0.1'
    ENV['SSHSCAN_API_PORT'] = '1337'
    ENV['SSHSCAN_DATABASE_HOST'] = '127.0.0.1'
    ENV['SSHSCAN_DATABASE_NAME'] = 'ssh_observatory'
    ENV['SSHSCAN_DATABASE_USERNAME'] = 'sshobs'
    SSHScan::Api::Api.new()
  end

  it "should be able to GET / correctly" do
    get "/"
    expect(last_response.status).to eql(200)
    expect(last_response.body).to eql(
      "See API documentation here: https://github.com/mozilla/ssh_scan_api/wiki/ssh_scan-Web-API\n"
    )
    expect(last_response["Content-Security-Policy"]).to eql("default-src 'none'; frame-ancestors 'none'; script-src 'none'; upgrade-insecure-requests") 
  end

  it "should be able to GET __version__ correctly" do
    get "/__version__"
    expect(last_response.status).to eql(200)
    expect(last_response.body).to eql({
      :api_version => SSHScan::Api::VERSION
    }.to_json)
    expect(last_response["Content-Security-Policy"]).to eql("default-src 'none'; frame-ancestors 'none'; script-src 'none'; upgrade-insecure-requests") 
  end

  it "should be able to POST /scan correctly" do
    bad_ip = "192.168.255.255"
    port = 22
    post "/api/v1/scan", {:target => bad_ip, :port => port}
    expect(last_response.status).to eql(200)
    expect(last_response["Content-Type"]).to eql("application/json")
    expect(last_response["Content-Security-Policy"]).to eql("default-src 'none'; frame-ancestors 'none'; script-src 'none'; upgrade-insecure-requests") 
  end

  it "should be able to GET /scan/results correctly" do
    get "/api/v1/scan/results"
    expect(last_response.status).to eql(200)
    expect(last_response.body).to eql({
      "error" => "no uuid specified"
    }.to_json)
    expect(last_response["Content-Security-Policy"]).to eql("default-src 'none'; frame-ancestors 'none'; script-src 'none'; upgrade-insecure-requests") 
  end

  it "should send a positive response on GET __lbheartbeat__\
  if the API is working" do
    get "/api/v1/__lbheartbeat__"
    expect(last_response.status).to eql(200)
    expect(last_response.body).to eql({
      :status => "OK",
      :message => "Keep sending requests. I am still alive."
    }.to_json)
    expect(last_response["Content-Type"]).to eql("application/json")
    expect(last_response["Content-Security-Policy"]).to eql("default-src 'none'; frame-ancestors 'none'; script-src 'none'; upgrade-insecure-requests") 
  end

  it "should generate a stats report" do
    get "/api/v1/stats"
    expect(last_response.status).to eql(200)

    parsed_response = JSON.parse(last_response.body)

    expect(parsed_response["SCAN_STATES"]).to be_kind_of(::Hash)
    expect(parsed_response["SCAN_STATES"].keys).to eql(["QUEUED", "BATCH_QUEUED", "RUNNING", "ERRORED", "COMPLETED"])
    parsed_response["SCAN_STATES"].values.each do |value|
      expect(value).to be_kind_of(::Integer)
    end
    expect(parsed_response["QUEUED_MAX_AGE"]).to be_kind_of(::Integer)
    expect(parsed_response["QUEUED_MAX_AGE"]).to be >= 0
    # expect(parsed_response["GRADE_REPORT"].keys).to eql(["A", "B", "C", "D", "F"])
    # parsed_response["GRADE_REPORT"].values.each do |value|
    #   expect(value).to be_kind_of(::Integer)
    # end
    # expect(parsed_response["AUTH_METHOD_REPORT"].keys).to eql(["publickey", "password"])
    # parsed_response["AUTH_METHOD_REPORT"].values do |value|
    #   expect(value).to be_kind_of(::Integer)
    # end
    expect(last_response["Content-Type"]).to eql("application/json")
    expect(last_response["Content-Security-Policy"]).to eql("default-src 'none'; frame-ancestors 'none'; script-src 'none'; upgrade-insecure-requests") 

  end

  it "should return an error for status check on non-existant uuid" do
    uuid = ::SecureRandom.uuid
    get "/api/v1/scan/results?uuid=uuid_string", {:uuid => uuid}

    expect(last_response.status).to eql(200)
    expect(last_response.body).to be_kind_of(::String)
    expect(last_response.body).to eql(
      {"scan": "UNKNOWN"}.to_json
    )
    expect(last_response["Content-Type"]).to eql("application/json")
    expect(last_response["Content-Security-Policy"]).to eql("default-src 'none'; frame-ancestors 'none'; script-src 'none'; upgrade-insecure-requests") 
  end

  it "should return string uuid" do
    ip = "127.0.0.1"
    port = 22
    post "/api/v1/scan", {:target => ip, :port => port}
    expect(last_response.status).to eql(200)
    expect(last_response.body).to be_kind_of(::String)
    parsed_response = JSON.parse(last_response.body)
    expect(parsed_response["uuid"]).to match(/^[\w]+{8}-[\w]+{4}-[\w]+{4}-[\w]+{4}-[\w]+{12}$/)
    expect(last_response["Content-Type"]).to eql("application/json")
    expect(last_response["Content-Security-Policy"]).to eql("default-src 'none'; frame-ancestors 'none'; script-src 'none'; upgrade-insecure-requests") 
  end

end
