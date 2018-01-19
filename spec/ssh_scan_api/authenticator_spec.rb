require 'spec_helper'
require 'ssh_scan_api/authenticator'

describe SSHScan::Authenticator do
  it "should have sane default behavior" do
    authenticator = SSHScan::Authenticator.new
    expect(authenticator.valid_token?("invalid_token")).to be false
  end

  it "should work for valid user tokens" do
    valid_token = SecureRandom.uuid
    invalid_token = SecureRandom.uuid
    config = {"users"=>[{"username"=>"starlord", "token"=> valid_token}]}
    authenticator = SSHScan::Authenticator.new(config)
    expect(authenticator.valid_token?(valid_token)).to be true
    expect(authenticator.valid_token?(invalid_token)).to be false
  end

  it "should work for valid worker tokens" do
    valid_token = SecureRandom.uuid
    invalid_token = SecureRandom.uuid
    config = {"workers"=>[{"worker_name"=>"worker1", "token"=> valid_token}]}
    authenticator = SSHScan::Authenticator.new(config)
    expect(authenticator.valid_token?(valid_token)).to be true
    expect(authenticator.valid_token?(invalid_token)).to be false
  end

  it "should create authenticator from a yaml file and validate tokens" do
    valid_token = SecureRandom.uuid
    invalid_token = SecureRandom.uuid

    config = {
      "port"=>8000,
      "authentication"=>false,
      "users"=>[
        {"username"=>"starlord", "token"=> valid_token},
      ],
      "database"=>{
        "type"=>"postgres",
        "name"=>"ssh_observatory",
        "server"=>"127.0.0.1",
        "port"=>5432
      }
    } 

    file = Tempfile.new('foo')
    file.write(config.to_yaml)
    file.close

    authenticator = SSHScan::Authenticator.from_config_file(file.path)
    expect(authenticator.valid_token?(valid_token)).to be true
    expect(authenticator.valid_token?(invalid_token)).to be false

    file.unlink
  end

end