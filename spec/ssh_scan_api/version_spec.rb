require 'spec_helper'
require 'rspec'
require 'ssh_scan_api/version'

describe SSHScan::API_VERSION do
  it "SSHScan::API_VERSION should be a string" do
    expect(SSHScan::API_VERSION).to be_kind_of(::String)
  end

  it "SSHScan::API_VERSION should have appropriate version" do
    tokens = SSHScan::API_VERSION.split(".")

    expect(tokens.size).to be_between(3,4).inclusive

	if tokens.size == 3
	  tokens.each do |token|
        expect(token).to be_kind_of(::String)
        expect(token.to_i).to be_between(0,50).inclusive
	  end
	else tokens.size == 4
	  expect(tokens[-1]).to match(/pre/)
	  tokens[0,3].each do |token|
        expect(token).to be_kind_of(::String)
        expect(token.to_i).to be_between(0,50).inclusive
	  end
	end
  end
end