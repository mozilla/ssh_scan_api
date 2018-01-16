require 'mongo'
require 'pg'
require 'json'

#This script was created to help with our migration from a MongoDB datastore to a Postgres datastore

# Get clients setup so we can talk to each database

mongo_client = Mongo::Client.new(["127.0.0.1:27017"], :database => "ssh_scan")[:ssh_scan]

postgres_client_opts = {
  :host => "127.0.0.1",
  :port => 5432,
  :user => "sshobs",
 #:password => "sshobspassword",
  :dbname => "ssh_observatory"
}
postgres_client = PG.connect(postgres_client_opts)

postgres_client.prepare("insert_migrated_record", "insert into scans (timestamp,target,port,state,uuid,worker_id,scan) values ($1, $2, $3, $4, $5, $6, $7)")

# For each record in the mongodb, insert a copy of the record into the postgres DB

mongo_client.find({}).each do |doc|
  target = doc["target"]
  port = doc["port"].to_s
  state = doc["status"]
  uuid = doc["uuid"]
  worker_id = doc["worker_id"]
  scan_result = doc["scan"].to_json
  timestamp = doc["_id"].generation_time

  postgres_client.exec_prepared("insert_migrated_record", [timestamp, target, port, state, uuid, worker_id, scan_result])
end