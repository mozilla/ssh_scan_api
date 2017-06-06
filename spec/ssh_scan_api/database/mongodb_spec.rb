require 'rspec'
require 'ssh_scan_api/database/mongo'
require 'securerandom'
require 'tempfile'
require 'json'

describe SSHScan::DB::MongoDb do
  before :each do
    opts = {
      "name" => "ssh_scan",
      "server" => "127.0.0.1",
      "port" => 27017
    }
    @mongodb = SSHScan::DB::MongoDb.from_hash(opts)
  end

  after :each do
    # Clean up the collection between unit-tests, to avoid collisions
    @mongodb.collection.delete_many({})
  end

  it "should #queue_scan in the collection" do
    uuid = SecureRandom.uuid
    socket = {"target" => "127.0.0.1", "port" => 1337}

    @mongodb.queue_scan(uuid, socket)

    # Emulate the retrieval process
    doc = @mongodb.collection.find(:uuid => uuid).first

    expect(doc["_id"]).to be_kind_of(::BSON::ObjectId)
    expect(doc["uuid"]).to eql(uuid)
    expect(doc["status"]).to eql("QUEUED")
    expect(doc["scan"]).to eql(nil)
    expect(doc["worker_id"]).to eql(nil)
  end

  it "should #run_scan in the collection" do
    uuid = SecureRandom.uuid
    socket = {"target" => "127.0.0.1", "port" => 1337}

    @mongodb.queue_scan(uuid, socket)

    # Emulate the retrieval process
    doc = @mongodb.collection.find(:uuid => uuid).first

    expect(doc["_id"]).to be_kind_of(::BSON::ObjectId)
    expect(doc["uuid"]).to eql(uuid)
    expect(doc["status"]).to eql("QUEUED")
    expect(doc["scan"]).to eql(nil)
    expect(doc["worker_id"]).to eql(nil)

    @mongodb.run_scan(uuid)

    doc = @mongodb.collection.find(:uuid => uuid).first
    expect(doc["status"]).to eql("RUNNING")
  end

  it "should give me the next queued scan via #next_queued_scan" do
    uuid1 = SecureRandom.uuid
    uuid2 = SecureRandom.uuid
    socket = {"target" => "127.0.0.1", "port" => 1337}

    @mongodb.queue_scan(uuid1, socket)
    @mongodb.queue_scan(uuid2, socket)

    doc = @mongodb.next_scan_in_queue
    expect(doc["_id"]).to be_kind_of(::BSON::ObjectId)
    expect(doc["uuid"]).to eql(uuid1)
    expect(doc["status"]).to eql("QUEUED")
    expect(doc["scan"]).to eql(nil)
    expect(doc["worker_id"]).to eql(nil)

    @mongodb.run_scan(uuid1)

    doc = @mongodb.next_scan_in_queue
    expect(doc["_id"]).to be_kind_of(::BSON::ObjectId)
    expect(doc["uuid"]).to eql(uuid2)
    expect(doc["status"]).to eql("QUEUED")
    expect(doc["scan"]).to eql(nil)
    expect(doc["worker_id"]).to eql(nil)
  end

  it "should give me the queue/running/complete/error counts" do
    uuid1 = SecureRandom.uuid
    uuid2 = SecureRandom.uuid
    worker_id = SecureRandom.uuid

    result = {"ssh_scan_version" => "0.0.21", "ip" => "127.0.0.1"}
    socket = {"target" => "127.0.0.1", "port" => 1337}

    @mongodb.queue_scan(uuid1, socket)
    @mongodb.queue_scan(uuid2, socket)

    expect(@mongodb.queue_count).to eql(2)
    expect(@mongodb.run_count).to eql(0)
    expect(@mongodb.complete_count).to eql(0)

    @mongodb.run_scan(uuid1)
    expect(@mongodb.queue_count).to eql(1)
    expect(@mongodb.run_count).to eql(1)
    expect(@mongodb.complete_count).to eql(0)

    @mongodb.complete_scan(uuid1, worker_id, result)
    expect(@mongodb.queue_count).to eql(1)
    expect(@mongodb.run_count).to eql(0)
    expect(@mongodb.complete_count).to eql(1)

    @mongodb.error_scan(uuid2, worker_id, result)
    expect(@mongodb.queue_count).to eql(0)
    expect(@mongodb.run_count).to eql(0)
    expect(@mongodb.complete_count).to eql(1)
    expect(@mongodb.error_count).to eql(1)
  end

  it "should be able to find all the scans via #find_scans" do
    uuid1 = SecureRandom.uuid
    uuid2 = SecureRandom.uuid

    socket = {"target" => "127.0.0.1", "port" => 1337}

    @mongodb.queue_scan(uuid1, socket)
    @mongodb.queue_scan(uuid2, socket)

    docs = @mongodb.find_scans(socket["target"], socket["port"])
    expect(docs.count).to eql(2)
  end


  it "should be able to find recent scan via #find_recent_scans" do
    uuid1 = SecureRandom.uuid
    uuid2 = SecureRandom.uuid

    socket = {"target" => "127.0.0.1", "port" => 1337}

    @mongodb.queue_scan(uuid1, socket)
    sleep 5
    @mongodb.queue_scan(uuid2, socket)

    docs = @mongodb.find_recent_scans(socket["target"], socket["port"], 2)
    expect(docs.count).to eql(1)

    doc = docs.first
    expect(doc["uuid"]).to eql(uuid2)
  end


  # it "should #add_scan scans to the collection" do
  #   worker_id = SecureRandom.uuid
  #   uuid = SecureRandom.uuid
  #   result = {"ip" => "127.0.0.1", "port" => 1337, "foo" => "bar", "biz" => "baz"}
  #   socket = {"target" => "127.0.0.1", "port" => 1337}

  #   temp_file = Tempfile.new('sqlite_database_file')

  #   @mongodb.add_scan(worker_id, uuid, result, socket)

  #   # Emulate the retrieval process
  #   doc = @mongodb.collection.find(:uuid => uuid).first

  #   expect(doc["_id"]).to be_kind_of(::BSON::ObjectId)
  #   expect(doc["uuid"]).to eql(uuid)
  #   expect(doc["scan"]).to eql(result)
  #   expect(doc["worker_id"]).to eql(worker_id)
  # end

  # it "should #delete_scan only the scan we ask it to" do
  #   worker_id = SecureRandom.uuid
  #   uuid1 = SecureRandom.uuid
  #   uuid2 = SecureRandom.uuid
  #   result = {"ip" => "127.0.0.1", "port" => 1337, "foo" => "bar", "biz" => "baz"}
  #   socket = {"target" => "127.0.0.1", "port" => 1337}

  #   @mongodb.add_scan(worker_id, uuid1, result, socket)
  #   @mongodb.add_scan(worker_id, uuid2, result, socket)

  #   # Verify that we now have two entries in the DB
  #   first_docs = @mongodb.collection.find(:worker_id => worker_id)
  #   expect(first_docs.count).to eql(2)

  #   # Let's delete one and make sure it's done
  #   @mongodb.delete_scan(uuid1)

  #   # Verify that we now have the right single entry left in the DB
  #   second_docs = @mongodb.collection.find(:worker_id => worker_id)
  #   expect(second_docs.count).to eql(1)
  #   expect(second_docs.first["uuid"]).to eql(uuid2)
  # end

  # it "should #delete_all scans in the collection" do
  #   worker_id = SecureRandom.uuid
  #   uuid1 = SecureRandom.uuid
  #   uuid2 = SecureRandom.uuid
  #   result = {"ip" => "127.0.0.1", "port" => 1337, "foo" => "bar", "biz" => "baz"}
  #   socket = {"target" => "127.0.0.1", "port" => 1337}

  #   @mongodb.add_scan(worker_id, uuid1, result, socket)
  #   @mongodb.add_scan(worker_id, uuid2, result, socket)

  #   # Let's delete all of them via the collection
  #   @mongodb.delete_all

  #   # Verify that we now have no scans in the collection
  #   docs = @mongodb.collection.find(:worker_id => worker_id)
  #   expect(docs.count).to eql(0)
  # end

  # it "should #find_scan_result in database" do
  #   worker_id = SecureRandom.uuid
  #   uuid1 = SecureRandom.uuid
  #   uuid2 = SecureRandom.uuid
  #   result1 = {"ip" => "127.0.0.1", "port" => 1337, "foo" => "bar", "biz" => "baz"}
  #   result2 = {"ip" => "127.0.0.1", "port" => 1337, "foo" => "bar2", "biz" => "baz2"}
  #   socket = {"target" => "127.0.0.1", "port" => 1337}

  #   @mongodb.add_scan(worker_id, uuid1, result1, socket)
  #   @mongodb.add_scan(worker_id, uuid2, result2, socket)

  #   # It should find the first scan
  #   response1 = @mongodb.find_scan_result(uuid1)
  #   expect(response1).to be_kind_of(::Hash)
  #   expect(response1).to eql(result1)

  #   # # It should find the second scan
  #   response2 = @mongodb.find_scan_result(uuid2)
  #   expect(response2).to be_kind_of(::Hash)
  #   expect(response2).to eql(result2)
  # end

  # it "should NOT #find_scan_result in database" do
  #   worker_id = SecureRandom.uuid
  #   uuid1 = SecureRandom.uuid
  #   bogus_uuid = SecureRandom.uuid
  #   result1 = {"ip" => "127.0.0.1", "port" => 1337, "foo" => "bar", "biz" => "baz"}
  #   socket = {"target" => "127.0.0.1", "port" => 1337}

  #   @mongodb.add_scan(worker_id, uuid1, result1, socket)

  #   # It should return nil for a non-existant uuid
  #   response = @mongodb.find_scan_result(bogus_uuid)
  #   expect(response).to eql(nil)
  # end

  # it "should #fetch_cached_result in database" do
  #   worker_id = SecureRandom.uuid
  #   uuid1 = SecureRandom.uuid
  #   uuid2 = SecureRandom.uuid
  #   scan_time = Time.now.to_s
  #   result1 = {"ip" => "127.0.0.1", "port" => 1337, "foo" => "bar", "biz" => "baz", "start_time" => scan_time}
  #   result2 = {"ip" => "127.0.0.2", "port" => 1337, "foo" => "bar", "biz" => "baz", "start_time" => scan_time}

  #   socket1 = {"target" => "127.0.0.1", "port" => 1337}
  #   socket2 = {"target" => "127.0.0.2", "port" => 1337}

  #   @mongodb.add_scan(worker_id, uuid1, result1, socket1)
  #   @mongodb.add_scan(worker_id, uuid2, result2, socket2)

  #   response = @mongodb.fetch_cached_result(socket1)
  #   expect(response["uuid"]).to eql(uuid1)
  #   expect(response["start_time"]).to eql(scan_time)

  #   response = @mongodb.fetch_cached_result(socket2)
  #   expect(response["uuid"]).to eql(uuid2)
  #   expect(response["start_time"]).to eql(scan_time)
  # end
end
