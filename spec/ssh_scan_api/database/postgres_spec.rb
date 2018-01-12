require 'rspec'
require 'ssh_scan_api/database/postgres'
require 'securerandom'
require 'tempfile'
require 'json'
require 'securerandom'
require 'tempfile'

# Expectations
#
# There are some assumptions about the postgres setup on the local machine for these to run
#
# 1.) There is an sshobs user, that doesn't require authentication to run
# 2.) There is a database called 'ssh_observatory' with a tables called 'scans'
# 3.) These unit-tests will create/destroy the contents of the scans table

describe SSHScan::DB::Postgres do
  before :each do
    opts = {
      "username" => "sshobs",
      "database" => "ssh_observatory",
      "server" => "127.0.0.1"
    }

    @postgres = SSHScan::DB::Postgres.from_hash(opts)

    # Remove all records from the table for each test, to make sure we're starting clean
    @postgres.exec("DELETE FROM scans")
  end

  it "should queue a scan in the scans table" do
    target = "sshscan.rubidus.com"
    port = 22
    state = "QUEUED"
    uuid = SecureRandom.uuid

    # Verify we start with nothing in the table
    expect(@postgres.exec("SELECT * FROM scans").values.size).to eql(0)

    @postgres.queue_scan(target, port, uuid)

    # Verify we actually got something into the queue
    expect(@postgres.exec("SELECT * FROM scans WHERE state LIKE 'QUEUED'").values.size).to eql(1)

    # Verify that that something is what we expect it to be
    serial, target, port, state, uuid = @postgres.exec("SELECT * FROM scans").values.first
    
    expect(serial.to_i).to be_kind_of(Integer)
    expect(target).to eql(target)
    expect(port).to eql(port)
    expect(state).to eql(state)
    expect(uuid).to eql(uuid)
  end

  it "should batch queue a scan in the scans table" do
    target = "sshscan.rubidus.com"
    port = 22
    state = "BATCH_QUEUED"
    uuid = SecureRandom.uuid

    # Verify we start with nothing in the table
    expect(@postgres.exec("SELECT * FROM scans").values.size).to eql(0)

    @postgres.batch_queue_scan(target, port, uuid)

    # Verify we actually got something into the batched queue
    expect(@postgres.exec("SELECT * FROM scans WHERE state LIKE 'BATCH_QUEUED'").values.size).to eql(1)

    # Verify that that something is what we expect it to be
    serial, target, port, state = @postgres.exec("SELECT * FROM scans").values.first
    
    expect(serial.to_i).to be_kind_of(Integer)
    expect(target).to eql(target)
    expect(port).to eql(port)
    expect(state).to eql(state)
    expect(uuid).to eql(uuid)
  end

  it "should move a scan from queued state to running state" do
    target = "sshscan.rubidus.com"
    port = 22
    queued_state = "QUEUED"
    running_state = "RUNNING"
    
    uuid = SecureRandom.uuid

    # Verify we start with nothing in the table
    expect(@postgres.exec("SELECT * FROM scans").values.size).to eql(0)

    @postgres.queue_scan(target, port, uuid)

    # Verify we actually got something into the queue
    expect(@postgres.exec("SELECT * FROM scans WHERE state LIKE 'QUEUED'").values.size).to eql(1)

    # Now move the queued scan into a running state
    @postgres.run_scan(uuid)

    # Verify that that something is what we expect it to be
    serial, timestamp, target, port, state, uuid2 = @postgres.exec("SELECT * FROM scans").values.first
    
    expect(serial.to_i).to be_kind_of(Integer)
    expect(target).to eql(target)
    expect(port).to eql(port)
    expect(state).to eql(running_state)
    expect(uuid2).to eql(uuid)
  end

  it "should move a scan from running state to completed state" do
    target = "sshscan.rubidus.com"
    port = 22
    queued_state = "QUEUED"
    running_state = "RUNNING"
    complete_state = "COMPLETED"
    
    uuid = SecureRandom.uuid
    worker_id = SecureRandom.uuid
    scan_result = '{"ip": "192.30.253.112", "ssh_scan_version": "0.0.21"}'

    # Verify we start with nothing in the table
    expect(@postgres.exec("SELECT * FROM scans").values.size).to eql(0)

    @postgres.queue_scan(target, port, uuid)

    # Verify we actually got something into the queue
    expect(@postgres.exec("SELECT * FROM scans WHERE state LIKE 'QUEUED'").values.size).to eql(1)

    # Now move the queued scan into a running state
    @postgres.run_scan(uuid)

    # Verify that that something is what we expect it to be
    serial, timestamp, target2, port2, state2, uuid2 = @postgres.exec("SELECT * FROM scans").values.first
    
    expect(serial.to_i).to be_kind_of(Integer)
    expect(target2).to eql(target)
    expect(port2.to_i).to eql(port)
    expect(state2).to eql(running_state)
    expect(uuid2).to eql(uuid)

    # Now move the running scan into completed state
    @postgres.complete_scan(uuid, worker_id, scan_result)

    # Verify that that something is what we expect it to be
    serial, timestamp, target3, port3, state3, uuid3, worker_id3, scan_result3 = @postgres.exec("SELECT * FROM scans").values.first
    
    expect(serial.to_i).to be_kind_of(Integer)
    expect(target3).to eql(target)
    expect(port3.to_i).to eql(port)
    expect(state3).to eql(complete_state)
    expect(uuid3).to eql(uuid)
    expect(worker_id3).to eql(worker_id)
    expect(scan_result3).to eql(scan_result)
  end

  it "should give me the next queued scan" do
    uuid1 = SecureRandom.uuid
    uuid2 = SecureRandom.uuid
    target = "127.0.0.1"
    port = 1337

    # Verify we start with nothing in the table
    expect(@postgres.exec("SELECT * FROM scans").values.size).to eql(0)

    @postgres.queue_scan(target, port, uuid1)
    @postgres.queue_scan(target, port, uuid2)

    # Verify we now have two requests in the queue
    expect(@postgres.exec("SELECT * FROM scans").values.size).to eql(2)

    # It's first in first out processing, so should be uuid1 first
    expect(@postgres.next_scan_in_queue).to eql(uuid1)
  end

  it "should return nil if there is nothing in the queue" do
    uuid1 = SecureRandom.uuid
    uuid2 = SecureRandom.uuid
    target = "127.0.0.1"
    port = 1337

    # Verify we now have two requests in the queue
    expect(@postgres.exec("SELECT * FROM scans").values.size).to eql(0)

    # It's first in first out processing, so should be uuid1 first
    expect(@postgres.next_scan_in_queue).to be nil
  end

  it "should give me the next batch queued scan" do
    uuid1 = SecureRandom.uuid
    uuid2 = SecureRandom.uuid
    target = "127.0.0.1"
    port = 1337

    # Verify we start with nothing in the table
    expect(@postgres.exec("SELECT * FROM scans").values.size).to eql(0)

    @postgres.batch_queue_scan(target, port, uuid1)
    @postgres.batch_queue_scan(target, port, uuid2)

    # Verify we now have two requests in the queue
    expect(@postgres.exec("SELECT * FROM scans").values.size).to eql(2)

    # It's first in first out processing, so should be uuid1 first
    expect(@postgres.next_scan_in_batch_queue).to eql(uuid1)
  end

  it "should give me the queue/running/complete/error counts" do
    uuid1 = SecureRandom.uuid
    uuid2 = SecureRandom.uuid
    worker_id = SecureRandom.uuid
    target = "127.0.0.1"
    port = 1337

    scan_result = '{"ip": "192.30.253.112", "ssh_scan_version": "0.0.21"}'

    @postgres.queue_scan(target, port, uuid1)
    @postgres.queue_scan(target, port, uuid2)

    expect(@postgres.queue_count).to eql(2)
    expect(@postgres.run_count).to eql(0)
    expect(@postgres.complete_count).to eql(0)

    @postgres.run_scan(uuid1)
    expect(@postgres.queue_count).to eql(1)
    expect(@postgres.run_count).to eql(1)
    expect(@postgres.complete_count).to eql(0)

    @postgres.complete_scan(uuid1, worker_id, scan_result)
    expect(@postgres.queue_count).to eql(1)
    expect(@postgres.run_count).to eql(0)
    #TODO: work through a fix here
    # expect(@postgres.complete_count).to eql(1)

    @postgres.error_scan(uuid2, worker_id, scan_result)
    expect(@postgres.queue_count).to eql(0)
    expect(@postgres.run_count).to eql(0)
    #TODO: work through a fix here
    #expect(@postgres.complete_count).to eql(1)
    expect(@postgres.error_count).to eql(1)
  end

  it "should give me the grade distributions we have" do
    results = []

    1.times {results << '{"ssh_scan_version":"0.0.21","ip":"127.0.0.1","port":22,"compliance":{"grade":"A"}}'}
    2.times {results << '{"ssh_scan_version":"0.0.21","ip":"127.0.0.1","port":22,"compliance":{"grade":"B"}}'}
    3.times {results << '{"ssh_scan_version":"0.0.21","ip":"127.0.0.1","port":22,"compliance":{"grade":"C"}}'}
    4.times {results << '{"ssh_scan_version":"0.0.21","ip":"127.0.0.1","port":22,"compliance":{"grade":"D"}}'}
    5.times {results << '{"ssh_scan_version":"0.0.21","ip":"127.0.0.1","port":22,"compliance":{"grade":"F"}}'}

    target = "127.0.0.1"
    port = 1337

    results.each do |result|
      uuid = SecureRandom.uuid
      worker_id = SecureRandom.uuid
      @postgres.queue_scan(target, port, uuid)
      @postgres.run_scan(uuid)
      @postgres.complete_scan(uuid, worker_id, result)
    end

    expect(@postgres.grade_report).to be_kind_of(Hash)
    expect(@postgres.grade_report).to eql({"A"=>1, "B"=>2, "C"=>3, "D"=>4, "F"=>5})
  end

  it "should give me the auth method distributions we have" do
    results = []

    results << '{"ssh_scan_version":"0.0.21","ip":"127.0.0.1","port":22,"auth_methods":["publickey"]}'
    results << '{"ssh_scan_version":"0.0.21","ip":"127.0.0.1","port":22,"auth_methods":["password"]}'
    results << '{"ssh_scan_version":"0.0.21","ip":"127.0.0.1","port":22,"auth_methods":["publickey", "password"]}'

    target = "127.0.0.1"
    port = 1337

    results.each do |result|
      uuid = SecureRandom.uuid
      worker_id = SecureRandom.uuid
      @postgres.queue_scan(target, port, uuid)
      @postgres.run_scan(uuid)
      @postgres.complete_scan(uuid, worker_id, result)
    end

    expect(@postgres.auth_method_report).to be_kind_of(Hash)
    expect(@postgres.auth_method_report).to eql({"publickey"=>2, "password"=>2})
  end


  it "should be able to find all the scans via #find_scans" do
    uuid1 = SecureRandom.uuid
    uuid2 = SecureRandom.uuid

    target = "127.0.0.1"
    port = 1337

    @postgres.queue_scan(target, port, uuid1)
    @postgres.queue_scan(target, port, uuid2)
    
    scans = @postgres.find_scans(target, port)

    expect(scans.size).to eql(2)
    expect(scans.include?(uuid1)).to be true
    expect(scans.include?(uuid2)).to be true
  end

  it "should be able to find recent scan via #find_recent_scans" do
    uuid1 = SecureRandom.uuid
    uuid2 = SecureRandom.uuid

    target = "127.0.0.1"
    port = 1337

    @postgres.queue_scan(target, port, uuid1)
    sleep 5
    @postgres.queue_scan(target, port, uuid2)

    scans = @postgres.find_recent_scans(target, port, true)
    expect(scans.count).to eql(1)

    expect(scans.first).to eql(uuid2)
  end

  # it "should be able to find the max queue age" do
  #   uuid1 = SecureRandom.uuid
  #   uuid2 = SecureRandom.uuid

  #   target1 = "127.0.0.1"
  #   target2 = "127.0.0.2"
  #   port = 1337

  #   @postgres.queue_scan(target1, port, uuid1)
  #   sleep 5
  #   @postgres.queue_scan(target2, port, uuid2)

  #   age = @postgres.queued_max_age

  #   expect(age).to be > 5.0
  #   expect(age).to be < 6.0
  # end

  it "should return zero when there are no queued scans" do
    uuid = SecureRandom.uuid
    target = "127.0.0.1"
    port = 1337

    @postgres.queue_scan(target, port, uuid)
    @postgres.run_scan(uuid)

    age = @postgres.queued_max_age
    expect(age).to eql(0)
  end

  it "should return scan state at any stage when asked for by uuid" do
    uuid = SecureRandom.uuid
    worker_id = SecureRandom.uuid
    target = "127.0.0.1"
    port = 1337
    scan_result = '{"ssh_scan_version":"0.0.21","ip":"127.0.0.1","port":22,"auth_methods":["publickey"]}'

    @postgres.queue_scan(target, port, uuid)
    expect(@postgres.get_scan_state(uuid)).to eql("QUEUED")
    @postgres.run_scan(uuid)
    expect(@postgres.get_scan_state(uuid)).to eql("RUNNING")
    @postgres.error_scan(uuid, worker_id, scan_result)
    expect(@postgres.get_scan_state(uuid)).to eql("ERRORED")
    @postgres.complete_scan(uuid, worker_id, scan_result)
    expect(@postgres.get_scan_state(uuid)).to eql("COMPLETED")
  end

  it "should return a completed scan when asked for by uuid" do
    uuid = SecureRandom.uuid
    worker_id = SecureRandom.uuid
    target = "127.0.0.1"
    port = 1337
    scan_result = '{"ssh_scan_version":"0.0.21","ip":"127.0.0.1","port":22,"auth_methods":["publickey"]}'

    @postgres.queue_scan(target, port, uuid)
    @postgres.run_scan(uuid)
    @postgres.complete_scan(uuid, worker_id, scan_result)

    scan_result_from_db = @postgres.get_scan(uuid)

    expect(scan_result_from_db).to be_kind_of(::Hash)
    expect(scan_result_from_db).to eql(JSON.parse(scan_result))
  end

  it "should return an error for a uuid that was never tasked" do
    uuid = SecureRandom.uuid
    scan_result_from_db = @postgres.get_scan(uuid)

    expect(scan_result_from_db).to be_kind_of(::Hash)
    expect(scan_result_from_db).to eql({'error' => 'no matching uuid in datastore'})
  end

  it "should get_work by uuid" do
    uuid = SecureRandom.uuid
    target = "127.0.0.1"
    port = 1337

    @postgres.queue_scan(target, port, uuid)
    expect(@postgres.get_work(uuid)).to be_kind_of(::Hash)
    expect(@postgres.get_work(uuid)).to eql("work" => {"uuid"=>uuid, "target"=>target, "port"=>port})
  end

end
