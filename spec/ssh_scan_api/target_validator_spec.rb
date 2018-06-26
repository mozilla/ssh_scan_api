require 'spec_helper'
require 'ssh_scan_api/target_validator'

describe SSHScan::Api::TargetValidator do
  it "should use defaults prescribed in constants" do  
    target_validator = SSHScan::Api::TargetValidator.new
    expect(target_validator.valid?("127.0.0.1")).to be false
    expect(target_validator.valid?("127.0.0.2")).to be false
    expect(target_validator.valid?("::1")).to be false
    expect(target_validator.valid?("ssh.mozilla.com")).to be true
    expect(target_validator.valid?("localhost")).to be false

    # Except these obvious invalids
    expect(target_validator.valid?(nil)).to be false
    expect(target_validator.valid?({})).to be false
    expect(target_validator.valid?("")).to be false
  end

  it "should observe invalid_regexes" do
    config = {
      "invalid_target_regexes" => [
        "^127"
      ],
      "invalid_target_strings" => [
      ]
    }
    target_validator = SSHScan::Api::TargetValidator.new(config)
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
      ],
      "invalid_target_regexes" => [
      ]
    }
    target_validator = SSHScan::Api::TargetValidator.new(config)
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
      ],
      "invalid_target_regexes" => [
      ]
    }
    target_validator = SSHScan::Api::TargetValidator.new(config)
    expect(target_validator.valid?("127.0.0.1")).to be true
    expect(target_validator.valid?("127.0.0.2")).to be true
    expect(target_validator.valid?("::1")).to be true
    expect(target_validator.valid?("lOcAlHoSt")).to be false
    expect(target_validator.valid?("github.com")).to be true
  end

  it "should invalid char on any invalid char" do
    target_validator = SSHScan::Api::TargetValidator.new()

    # individual chars
    expect(target_validator.invalid_char?("/")).to be true
    expect(target_validator.invalid_char?("a")).to be false
    expect(target_validator.invalid_char?("A")).to be false
    expect(target_validator.invalid_char?("1")).to be false
    expect(target_validator.invalid_char?(":")).to be false
    expect(target_validator.invalid_char?(".")).to be false
    expect(target_validator.invalid_char?(" ")).to be true
    expect(target_validator.invalid_char?("|")).to be true
    expect(target_validator.invalid_char?("&")).to be true
    expect(target_validator.invalid_char?(";")).to be true

    # parent valid?/invalid? checking of the same thing (but as a substring)
    expect(target_validator.invalid?("http://mywebsite")).to be true
    expect(target_validator.valid?("a.b.c")).to be true
  end

end
