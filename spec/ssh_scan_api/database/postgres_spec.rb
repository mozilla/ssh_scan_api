require 'rspec'
require 'ssh_scan_api/database/postgres'
require 'securerandom'
require 'tempfile'
require 'json'
require 'securerandom'
require 'tempfile'

describe SSHScan::DB::Postgres do
  before :each do
    opts = {
      "server" => "127.0.0.1",
      "port" => 5433      
    }
    @postgres = SSHScan::DB::Postgres.from_hash(opts)
  end

  it "should create/delete databases when we ask" do
    # Generate a random string for the database name
    database_name = "test_database"

    # Create the ssh_scan database from scratch
    @postgres.create(database_name)

    # Verify that we actually created the database
    expect(@postgres.exists?(database_name)).to be true

    # Clean up after ourselves, by deleting the database
    @postgres.delete(database_name)
    expect(@postgres.exists?(database_name)).to be false
  end

  it "should run SQL files from disk" do
    database_name = "test_database2"

    # Verify an initial state of no database matching this name
    expect(@postgres.exists?(database_name)).to be false

    file = Tempfile.new('foo')
    file.write("CREATE DATABASE #{database_name};")
    file.close

    @postgres.exec_file(file.path)
    expect(@postgres.exists?(database_name)).to be true

    # Clean up after ourselves, by deleting the database
    @postgres.delete(database_name)
    expect(@postgres.exists?(database_name)).to be false
  end

  it "should initialize the schema" do
    database_name = "test_database3"
    @postgres.delete(database_name)

    # Verify an initial state of no database matching this name
    expect(@postgres.exists?(database_name)).to be false

    # Create the database and verify it's existence
    @postgres.create(database_name)
    expect(@postgres.exists?(database_name)).to be true

    # Load the project schema
    @postgres.initalize
    @postgres.table_exists?(database_name, "scans"). #TODO fix this, make it work

    # Clean up after ourselves, by deleting the database
    @postgres.delete(database_name)
    expect(@postgres.exists?(database_name)).to be false
  end


  # it "should #queue_scan in the collection" do
  #   uuid = SecureRandom.uuid
  #   socket = {"target" => "127.0.0.1", "port" => 1337}

  #   @mongodb.queue_scan(uuid, socket)

  #   # Emulate the retrieval process
  #   doc = @mongodb.collection.find(:uuid => uuid).first

  #   expect(doc["_id"]).to be_kind_of(::BSON::ObjectId)
  #   expect(doc["uuid"]).to eql(uuid)
  #   expect(doc["status"]).to eql("QUEUED")
  #   expect(doc["scan"]).to eql(nil)
  #   expect(doc["worker_id"]).to eql(nil)
  # end

  # it "should #batch_queue_scan in the collection" do
  #   uuid = SecureRandom.uuid
  #   socket = {"target" => "127.0.0.1", "port" => 1337}

  #   @mongodb.batch_queue_scan(uuid, socket)

  #   # Emulate the retrieval process
  #   doc = @mongodb.collection.find(:uuid => uuid).first

  #   expect(doc["_id"]).to be_kind_of(::BSON::ObjectId)
  #   expect(doc["uuid"]).to eql(uuid)
  #   expect(doc["status"]).to eql("BATCH_QUEUED")
  #   expect(doc["scan"]).to eql(nil)
  #   expect(doc["worker_id"]).to eql(nil)
  # end

  # it "should #run_scan in the collection" do
  #   uuid = SecureRandom.uuid
  #   socket = {"target" => "127.0.0.1", "port" => 1337}

  #   @mongodb.queue_scan(uuid, socket)

  #   # Emulate the retrieval process
  #   doc = @mongodb.collection.find(:uuid => uuid).first

  #   expect(doc["_id"]).to be_kind_of(::BSON::ObjectId)
  #   expect(doc["uuid"]).to eql(uuid)
  #   expect(doc["status"]).to eql("QUEUED")
  #   expect(doc["scan"]).to eql(nil)
  #   expect(doc["worker_id"]).to eql(nil)

  #   @mongodb.run_scan(uuid)

  #   doc = @mongodb.collection.find(:uuid => uuid).first
  #   expect(doc["status"]).to eql("RUNNING")
  # end

  # it "should give me the next queued scan via #next_queued_scan" do
  #   uuid1 = SecureRandom.uuid
  #   uuid2 = SecureRandom.uuid
  #   socket = {"target" => "127.0.0.1", "port" => 1337}

  #   @mongodb.queue_scan(uuid1, socket)
  #   @mongodb.queue_scan(uuid2, socket)

  #   doc = @mongodb.next_scan_in_queue
  #   expect(doc["_id"]).to be_kind_of(::BSON::ObjectId)
  #   expect(doc["uuid"]).to eql(uuid1)
  #   expect(doc["status"]).to eql("QUEUED")
  #   expect(doc["scan"]).to eql(nil)
  #   expect(doc["worker_id"]).to eql(nil)

  #   @mongodb.run_scan(uuid1)

  #   doc = @mongodb.next_scan_in_queue
  #   expect(doc["_id"]).to be_kind_of(::BSON::ObjectId)
  #   expect(doc["uuid"]).to eql(uuid2)
  #   expect(doc["status"]).to eql("QUEUED")
  #   expect(doc["scan"]).to eql(nil)
  #   expect(doc["worker_id"]).to eql(nil)
  # end

  # it "should give me the queue/running/complete/error counts" do
  #   uuid1 = SecureRandom.uuid
  #   uuid2 = SecureRandom.uuid
  #   worker_id = SecureRandom.uuid

  #   result = {"ssh_scan_version" => "0.0.21", "ip" => "127.0.0.1"}
  #   socket = {"target" => "127.0.0.1", "port" => 1337}

  #   @mongodb.queue_scan(uuid1, socket)
  #   @mongodb.queue_scan(uuid2, socket)

  #   expect(@mongodb.queue_count).to eql(2)
  #   expect(@mongodb.run_count).to eql(0)
  #   expect(@mongodb.complete_count).to eql(0)

  #   @mongodb.run_scan(uuid1)
  #   expect(@mongodb.queue_count).to eql(1)
  #   expect(@mongodb.run_count).to eql(1)
  #   expect(@mongodb.complete_count).to eql(0)

  #   @mongodb.complete_scan(uuid1, worker_id, result)
  #   expect(@mongodb.queue_count).to eql(1)
  #   expect(@mongodb.run_count).to eql(0)
  #   expect(@mongodb.complete_count).to eql(1)

  #   @mongodb.error_scan(uuid2, worker_id, result)
  #   expect(@mongodb.queue_count).to eql(0)
  #   expect(@mongodb.run_count).to eql(0)
  #   expect(@mongodb.complete_count).to eql(1)
  #   expect(@mongodb.error_count).to eql(1)
  # end

  # it "should give me the grade distributions we have" do
  #   results = []

  #   1.times {results << {"ssh_scan_version" => "0.0.21", "ip" => "127.0.0.1", "compliance" => {"grade" => "A"}}}
  #   2.times {results << {"ssh_scan_version" => "0.0.21", "ip" => "127.0.0.1", "compliance" => {"grade" => "B"}}}
  #   3.times {results << {"ssh_scan_version" => "0.0.21", "ip" => "127.0.0.1", "compliance" => {"grade" => "C"}}}
  #   4.times {results << {"ssh_scan_version" => "0.0.21", "ip" => "127.0.0.1", "compliance" => {"grade" => "D"}}}
  #   5.times {results << {"ssh_scan_version" => "0.0.21", "ip" => "127.0.0.1", "compliance" => {"grade" => "F"}}}

  #   socket = {"target" => "127.0.0.1", "port" => 1337}

  #   results.each do |result|
  #     uuid = SecureRandom.uuid
  #     worker_id = SecureRandom.uuid
  #     @mongodb.queue_scan(uuid, socket)
  #     @mongodb.run_scan(uuid)
  #     @mongodb.complete_scan(uuid, worker_id, result)
  #   end

  #   expect(@mongodb.grade_report).to be_kind_of(Hash)
  #   expect(@mongodb.grade_report).to eql({"A"=>1, "B"=>2, "C"=>3, "D"=>4, "F"=>5})
  # end

  # it "should give me the auth method distributions we have" do
  #   results = []

  #   results << {"ssh_scan_version" => "0.0.21", "ip" => "127.0.0.1", "auth_methods" => ["publickey"]}
  #   results << {"ssh_scan_version" => "0.0.21", "ip" => "127.0.0.1", "auth_methods" => ["password"]}
  #   results << {"ssh_scan_version" => "0.0.21", "ip" => "127.0.0.1", "auth_methods" => ["publickey", "password"]}

  #   socket = {"target" => "127.0.0.1", "port" => 1337}

  #   results.each do |result|
  #     uuid = SecureRandom.uuid
  #     worker_id = SecureRandom.uuid
  #     @mongodb.queue_scan(uuid, socket)
  #     @mongodb.run_scan(uuid)
  #     @mongodb.complete_scan(uuid, worker_id, result)
  #   end

  #   expect(@mongodb.auth_method_report).to be_kind_of(Hash)
  #   expect(@mongodb.auth_method_report).to eql({"publickey"=>2, "password"=>2})
  # end


  # it "should be able to find all the scans via #find_scans" do
  #   uuid1 = SecureRandom.uuid
  #   uuid2 = SecureRandom.uuid

  #   socket = {"target" => "127.0.0.1", "port" => 1337}

  #   @mongodb.queue_scan(uuid1, socket)
  #   @mongodb.queue_scan(uuid2, socket)

  #   docs = @mongodb.find_scans(socket["target"], socket["port"])
  #   expect(docs.count).to eql(2)
  # end


  # it "should be able to find recent scan via #find_recent_scans" do
  #   uuid1 = SecureRandom.uuid
  #   uuid2 = SecureRandom.uuid

  #   socket = {"target" => "127.0.0.1", "port" => 1337}

  #   @mongodb.queue_scan(uuid1, socket)
  #   sleep 5
  #   @mongodb.queue_scan(uuid2, socket)

  #   docs = @mongodb.find_recent_scans(socket["target"], socket["port"], 2)
  #   expect(docs.count).to eql(1)

  #   doc = docs.first
  #   expect(doc["uuid"]).to eql(uuid2)
  # end

  # it "should be able to find the max queue age" do
  #   uuid1 = SecureRandom.uuid
  #   uuid2 = SecureRandom.uuid

  #   socket1 = {"target" => "127.0.0.1", "port" => 1337}
  #   socket2 = {"target" => "127.0.0.2", "port" => 1337}

  #   @mongodb.queue_scan(uuid1, socket1)
  #   sleep 5
  #   @mongodb.queue_scan(uuid2, socket2)

  #   age = @mongodb.queued_max_age

  #   expect(age).to be > 5.0
  #   expect(age).to be < 6.0
  # end

  # it "should return zero when there are no queued scans" do
  #   uuid1 = SecureRandom.uuid
  #   socket1 = {"target" => "127.0.0.1", "port" => 1337}

  #   @mongodb.queue_scan(uuid1, socket1)
  #   @mongodb.run_scan(uuid1)

  #   age = @mongodb.queued_max_age
  #   expect(age).to eql(0)
  # end

end
