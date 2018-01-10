require 'pg'

module SSHScan
  module DB
    class Postgres
      def initialize(client)
        @client = client
        initialize_prepared_statements
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

      def initialize_prepared_statements
        @client.prepare("queue_scan", "insert into scans (target,port,state,uuid) values ($1, $2, $3, $4)")
        @client.prepare("batch_queue_scan", "insert into scans (target,port,state,uuid) values ($1, $2, $3, $4)")
        @client.prepare("run_scan", "update scans SET state = 'RUNNING' where uuid = $1")
        @client.prepare("complete_scan", "update scans SET (state,worker_id,scan) = ('COMPLETED',$1,$2) where uuid = $3")
        @client.prepare("error_scan", "update scans SET (state,worker_id,scan) = ('ERRORED',$1,$2) where uuid = $3")
      end

      def queue_scan(target, port, uuid)
        @client.exec_prepared("queue_scan", [target, port, "QUEUED", uuid])
      end

      def batch_queue_scan(target, port, uuid)
        @client.exec_prepared("batch_queue_scan", [target, port, "BATCH_QUEUED", uuid])
      end

      def run_count
        results = @client.exec("SELECT COUNT(*) FROM scans WHERE state = 'RUNNING'").values
        return 0 if results.empty?
        return results.first.first.to_i
      end

      def queue_count
        results = @client.exec("SELECT COUNT(*) FROM scans WHERE state = 'QUEUED'").values
        return 0 if results.empty?
        return results.first.first.to_i
      end

      def batch_queue_count
        results = @client.exec("SELECT COUNT(*) FROM scans WHERE state = 'BATCH_QUEUED'").values
        return 0 if results.empty?
        return results.first.first.to_i
      end

      def error_count
        results = @client.exec("SELECT COUNT(*) FROM scans WHERE state = 'ERRORED'").values
        return 0 if results.empty?
        return results.first.first.to_i
      end

      def complete_count
        results = @client.exec("SELECT COUNT(*) FROM scans WHERE state = 'COMPLETE'").values
        return 0 if results.empty?
        return results.first.first.to_i
      end

      def total_count
        results = @client.exec("SELECT COUNT(*) FROM scans").values
        return 0 if results.empty?
        return results.first.first.to_i
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
        @client.exec_prepared("run_scan", [uuid])
      end

      def get_scan(uuid)
        # @collection.find(uuid: uuid).first
      end

      def complete_scan(uuid, worker_id, scan_result)
        @client.exec_prepared("complete_scan", [worker_id, scan_result, uuid])
      end

      def error_scan(uuid, worker_id, scan_result)
        @client.exec_prepared("error_scan", [worker_id, scan_result, uuid])
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
        results = @client.exec("SELECT uuid FROM scans WHERE state = 'BATCH_QUEUED' LIMIT 1").values
        return nil if results.empty?
        return results.first.first
      end

      def next_scan_in_queue
        results = @client.exec("SELECT uuid FROM scans WHERE state = 'QUEUED' LIMIT 1").values
        return nil if results.empty?
        return results.first.first
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
