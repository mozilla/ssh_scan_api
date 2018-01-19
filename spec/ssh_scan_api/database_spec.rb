require 'spec_helper'
require 'rspec'
require 'ssh_scan_api/database'
require 'securerandom'
require 'tempfile'

describe SSHScan::Database do
  before :each do
    @test_database = double("test_database")
    @abstract_database = SSHScan::Database.new(@test_database)
  end

  it "should behave like an SSHScan::Database object" do
    expect(@abstract_database.database).to be_kind_of(RSpec::Mocks::Double)
    expect(@abstract_database.respond_to?(:run_count)).to be true
    expect(@abstract_database.respond_to?(:queue_count)).to be true
    expect(@abstract_database.respond_to?(:error_count)).to be true
    expect(@abstract_database.respond_to?(:complete_count)).to be true
    expect(@abstract_database.respond_to?(:run_scan)).to be true
    expect(@abstract_database.respond_to?(:complete_scan)).to be true
    expect(@abstract_database.respond_to?(:error_scan)).to be true
    expect(@abstract_database.respond_to?(:next_scan_in_queue)).to be true
    expect(@abstract_database.respond_to?(:find_recent_scans)).to be true
    expect(@abstract_database.respond_to?(:find_scans)).to be true
    expect(@abstract_database.respond_to?(:queued_max_age)).to be true
  end

  it "should defer #run_count calls to the specific DB implementation" do
    worker_id = SecureRandom.uuid
    uuid = SecureRandom.uuid
    result = {:ip => "127.0.0.1", :port => 1337, :foo => "bar", :biz => "baz"}
    socket = {:target => "127.0.0.1", :port => 1337}

    expect(@test_database).to receive(:run_count)
    @abstract_database.run_count
  end

  it "should defer #queue_count calls to the specific DB implementation" do
    worker_id = SecureRandom.uuid
    uuid = SecureRandom.uuid
    result = {:ip => "127.0.0.1", :port => 1337, :foo => "bar", :biz => "baz"}
    socket = {:target => "127.0.0.1", :port => 1337}

    expect(@test_database).to receive(:queue_count)
    @abstract_database.queue_count
  end

  it "should defer #error_count calls to the specific DB implementation" do
    worker_id = SecureRandom.uuid
    uuid = SecureRandom.uuid
    result = {:ip => "127.0.0.1", :port => 1337, :foo => "bar", :biz => "baz"}
    socket = {:target => "127.0.0.1", :port => 1337}

    expect(@test_database).to receive(:error_count)
    @abstract_database.error_count
  end

  it "should defer #complete_count calls to the specific DB implementation" do
    worker_id = SecureRandom.uuid
    uuid = SecureRandom.uuid
    result = {:ip => "127.0.0.1", :port => 1337, :foo => "bar", :biz => "baz"}
    socket = {:target => "127.0.0.1", :port => 1337}

    expect(@test_database).to receive(:complete_count)
    @abstract_database.complete_count
  end

  it "should defer #queue_scan calls to the specific DB implementation" do
    uuid = SecureRandom.uuid
    target = "127.0.0.1"
    port = 1337

    expect(@test_database).to receive(:queue_scan).with(target, port, uuid)
    @abstract_database.queue_scan(target, port, uuid)
  end

  it "should defer #run_scan calls to the specific DB implementation" do
    worker_id = SecureRandom.uuid
    uuid = SecureRandom.uuid
    result = {:ip => "127.0.0.1", :port => 1337, :foo => "bar", :biz => "baz"}
    socket = {:target => "127.0.0.1", :port => 1337}

    expect(@test_database).to receive(:run_scan).with(uuid)
    @abstract_database.run_scan(uuid)
  end

  it "should defer #complete_scan calls to the specific DB implementation" do
    worker_id = SecureRandom.uuid
    uuid = SecureRandom.uuid
    result = {:ip => "127.0.0.1", :port => 1337, :foo => "bar", :biz => "baz"}
    socket = {:target => "127.0.0.1", :port => 1337}

    expect(@test_database).to receive(:complete_scan).with(uuid, worker_id, result)
    @abstract_database.complete_scan(uuid, worker_id, result)
  end

  it "should defer #get_work calls to the specific DB implementation" do
    worker_id = SecureRandom.uuid
    uuid = SecureRandom.uuid
    result = {:ip => "127.0.0.1", :port => 1337, :foo => "bar", :biz => "baz"}
    socket = {:target => "127.0.0.1", :port => 1337}

    expect(@test_database).to receive(:get_work).with(uuid)
    @abstract_database.get_work(uuid)
  end

  it "should defer #get_scan calls to the specific DB implementation" do
    worker_id = SecureRandom.uuid
    uuid = SecureRandom.uuid
    result = {:ip => "127.0.0.1", :port => 1337, :foo => "bar", :biz => "baz"}
    socket = {:target => "127.0.0.1", :port => 1337}

    expect(@test_database).to receive(:get_scan).with(uuid)
    @abstract_database.get_scan(uuid)
  end

  it "should defer #get_scan_state calls to the specific DB implementation" do
    worker_id = SecureRandom.uuid
    uuid = SecureRandom.uuid
    result = {:ip => "127.0.0.1", :port => 1337, :foo => "bar", :biz => "baz"}
    socket = {:target => "127.0.0.1", :port => 1337}

    expect(@test_database).to receive(:get_scan_state).with(uuid)
    @abstract_database.get_scan_state(uuid)
  end

  it "should defer #error_scan calls to the specific DB implementation" do
    worker_id = SecureRandom.uuid
    uuid = SecureRandom.uuid
    result = {:ip => "127.0.0.1", :port => 1337, :foo => "bar", :biz => "baz"}
    socket = {:target => "127.0.0.1", :port => 1337}

    expect(@test_database).to receive(:error_scan).with(uuid, worker_id, result)
    @abstract_database.error_scan(uuid, worker_id, result)
  end

  it "should defer #next_scan_in_queue calls to the specific DB implementation" do
    worker_id = SecureRandom.uuid
    uuid = SecureRandom.uuid
    result = {:ip => "127.0.0.1", :port => 1337, :foo => "bar", :biz => "baz"}
    socket = {:target => "127.0.0.1", :port => 1337}

    expect(@test_database).to receive(:next_scan_in_queue)
    @abstract_database.next_scan_in_queue
  end

  it "should defer #find_recent_scans calls to the specific DB implementation" do
    worker_id = SecureRandom.uuid
    uuid = SecureRandom.uuid
    result = {:ip => "127.0.0.1", :port => 1337, :foo => "bar", :biz => "baz"}
    socket = {:target => "127.0.0.1", :port => 1337}
    ip = "127.0.0.1"
    port = 1337
    seconds_old = 2

    expect(@test_database).to receive(:find_recent_scans).with(ip, port, seconds_old)
    @abstract_database.find_recent_scans(ip, port, seconds_old)
  end

  it "should defer #find_scans calls to the specific DB implementation" do
    worker_id = SecureRandom.uuid
    uuid = SecureRandom.uuid
    result = {:ip => "127.0.0.1", :port => 1337, :foo => "bar", :biz => "baz"}
    socket = {:target => "127.0.0.1", :port => 1337}
    ip = "127.0.0.1"
    port = 1337

    expect(@test_database).to receive(:find_scans).with(ip, port)
    @abstract_database.find_scans(ip, port)
  end
end
