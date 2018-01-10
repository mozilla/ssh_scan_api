require 'pg'

module SSHScan
  module DB
    class Postgres
      def initialize(client)
        @client = client
      end

      # Helps us create a SSHScan::DB::Postgres object with a hash
      def self.from_hash(opts)
        database = opts["name"] || "ssh_observatory"
        server = ENV['sshscan.database.host'] || opts["server"]
        port = opts["port"]
        username = opts["username"]
        password = opts["password"]

        client = PG.connect( host: server, port: port, user: username, password: password, dbname: database )
        return SSHScan::DB::Postgres.new(client)
      end

      def exec(sql)
        @client.exec(sql)
      end

      def queue_scan(target, port)
        @client.prepare("queue_scan", "insert into scans (target,port,state) values ($1, $2, $3)")
        @client.exec_prepared("queue_scan", [target, port, "QUEUED"])
      end

      def batch_queue_scan(target, port)
        @client.prepare("batch_queue_scan", "insert into scans (target,port,state) values ($1, $2, $3)")
        @client.exec_prepared("batch_queue_scan", [target, port, "BATCH_QUEUED"])
      end

      def run_count
        # @collection.count(status: 'RUNNING')
      end

      def queue_count
        # @collection.count(status: 'QUEUED')
      end

      def batch_queue_count
        # @collection.count(status: 'BATCH_QUEUED')
      end

      def error_count
        # @collection.count(status: 'ERRORED')
      end

      def complete_count
        # @collection.count(status: 'COMPLETED')
      end

      def total_count
        # @collection.count
      end

      # The age of the oldest record in QUEUED state, in seconds
      def queued_max_age
        # max_age = 0
        
        # @collection.find(status: 'QUEUED').each do |item|
        #   age = Time.now - item["queue_time"]
        #   if age > max_age
        #     max_age = age
        #   end
        # end

        # return max_age
      end

      def run_scan(uuid)
        # @collection.find(uuid: uuid).update_one(
        #   '$set'=> { 'status' => 'RUNNING' }
        # )
      end

      def get_scan(uuid)
        # @collection.find(uuid: uuid).first
      end

      def complete_scan(uuid, worker_id, result)
        # @collection.find(uuid: uuid).update_one(
        #   '$set'=> { 
        #     'status' => 'COMPLETED',
        #     'worker_id' => worker_id,
        #     'scan' => result
        #   }
        # )
      end

      def error_scan(uuid, worker_id, result)
        # @collection.find(uuid: uuid).update_one(
        #   '$set'=> { 
        #     'status' => 'ERRORED',
        #     'worker_id' => worker_id,
        #     'scan' => result
        #   }
        # )
      end

      def auth_method_report
        # auth_methods = [
        #   "publickey",
        #   "password"
        # ]

        # histogram = {}

        # auth_methods.each do |auth_method|
        #   histogram[auth_method] = @collection.count("scan.auth_methods": auth_method)
        # end

        # return histogram
      end

      def grade_report
        # grades = ["A", "B", "C", "D", "F"]
        # histogram = {}

        # grades.each do |grade|
        #   histogram[grade] = @collection.count("scan.compliance.grade": grade)
        # end
        
        # return histogram
      end

      def next_scan_in_batch_queue
        # @collection.find(status: "BATCH_QUEUED").first
      end

      def next_scan_in_queue
        # @collection.find(status: "QUEUED").first
      end

      def find_recent_scans(ip, port, seconds_old)
        # results = []

        # # TODO: make this part of the query so it doesn't turn into a perf issue
        # @collection.find("target" => ip, "port" => port).each do |result|
        #   if Time.now - result["_id"].generation_time < seconds_old
        #     results << result
        #   end
        # end

        # return results
      end

      def find_scans(ip, port)
        # @collection.find("target" => ip, "port" => port)
      end
    end
  end
end
