require 'spec_helper'
require 'rspec'
require 'ssh_scan_api/version'

describe SSHScan::API_VERSION do
  it "SSHScan::API_VERSION should be a string" do
    expect(SSHScan::API_VERSION).to be_kind_of(::String)
  end

  it "SSHScan::API_VERSION should have 1 level" do
    expect(SSHScan::API_VERSION.split('.').size).to eql(1)
  end

  it "SSHScan::API_VERSION should have a number between 1-20 for each octet" do
    expect(SSHScan::API_VERSION).to eql("1")
  end
end