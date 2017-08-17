require 'spec_helper'
require 'ssh_scan_api/target_validator'

describe SSHScan::TargetValidator do
  it "should allow anything sane by default" do  
    target_validator = SSHScan::TargetValidator.new
    expect(target_validator.valid?("127.0.0.1")).to be true
    expect(target_validator.valid?("127.0.0.2")).to be true
    expect(target_validator.valid?("::1")).to be true
    expect(target_validator.valid?("ssh.mozilla.com")).to be true
    expect(target_validator.valid?("localhost")).to be true

    # Except these obvious invalids
    expect(target_validator.valid?(nil)).to be false
    expect(target_validator.valid?({})).to be false
    expect(target_validator.valid?("")).to be false
  end

  it "should observe invalid_regexes" do
    config = {
      "invalid_target_regexes" => [
        "^127"
      ]
    }
    target_validator = SSHScan::TargetValidator.new(config)
    expect(target_validator.valid?("127.0.0.1")).to be false
    expect(target_validator.valid?("127.0.0.2")).to be false
    expect(target_validator.valid?("::1")).to be true
    expect(target_validator.valid?("localhost")).to be true
    expect(target_validator.valid?("github.com")).to be true
  end

  it "should observe invalid_strings (same case)" do
    config = {
      "invalid_target_strings" => [
        "localhost"
      ]
    }
    target_validator = SSHScan::TargetValidator.new(config)
    expect(target_validator.valid?("127.0.0.1")).to be true
    expect(target_validator.valid?("127.0.0.2")).to be true
    expect(target_validator.valid?("::1")).to be true
    expect(target_validator.valid?("localhost")).to be false
    expect(target_validator.valid?("github.com")).to be true
  end

  it "should observe invalid_strings (different case)" do
    config = {
      "invalid_target_strings" => [
        "localhost"
      ]
    }
    target_validator = SSHScan::TargetValidator.new(config)
    expect(target_validator.valid?("127.0.0.1")).to be true
    expect(target_validator.valid?("127.0.0.2")).to be true
    expect(target_validator.valid?("::1")).to be true
    expect(target_validator.valid?("lOcAlHoSt")).to be false
    expect(target_validator.valid?("github.com")).to be true
  end

  it "work the same when coming from a config file" do
    config_path = "./config/api/config.yml"
    target_validator = SSHScan::TargetValidator.new(config_path)
    expect(target_validator.valid?("127.0.0.1")).to be false
    expect(target_validator.valid?("127.0.0.2")).to be false
    expect(target_validator.valid?("::1")).to be false
    expect(target_validator.valid?("localhost")).to be false
    expect(target_validator.valid?("github.com")).to be true
  end

end