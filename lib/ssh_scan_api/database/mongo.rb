require 'mongo'

Mongo::Logger.logger.level = ::Logger::FATAL

module SSHScan
  module DB
    class MongoDb
      attr_reader :collection

      def initialize(client)
        @client = client
        @collection = @client[:ssh_scan]
      end

      # Helps us create a SSHScan::DB::MongoDB object with a hash
      def self.from_hash(opts)
        name = opts["name"]
        server = opts["server"]
        port = opts["port"]
        socket = server + ":" + port.to_s

        client = Mongo::Client.new([socket], :database => name)
        return SSHScan::DB::MongoDb.new(client)
      end

      def queue_scan(uuid, socket)
        @collection.insert_one(
          "uuid" => uuid,
          "target" => socket["target"],
          "port" => socket["port"].to_i,
          "status" => "QUEUED",
          "scan" => nil,
          "worker_id" => nil,
        )
      end

      def run_count
        @collection.count(status: 'RUNNING')
      end

      def queue_count
        @collection.count(status: 'QUEUED')
      end

      def error_count
        @collection.count(status: 'ERRORED')
      end

      def complete_count
        @collection.count(status: 'COMPLETED')
      end

      def total_count
        @collection.count
      end

      def run_scan(uuid)
        @collection.find(uuid: uuid).update_one(
          '$set'=> { 'status' => 'RUNNING' }
        )
      end

      def get_scan(uuid)
        @collection.find(uuid: uuid).first
      end

      def complete_scan(uuid, worker_id, result)
        @collection.find(uuid: uuid).update_one(
          '$set'=> { 
            'status' => 'COMPLETED',
            'worker_id' => worker_id,
            'scan' => result
          }
        )
      end

      def error_scan(uuid, worker_id, result)
        @collection.find(uuid: uuid).update_one(
          '$set'=> { 
            'status' => 'ERRORED',
            'worker_id' => worker_id,
            'scan' => result
          }
        )
      end

      def next_scan_in_queue()
        @collection.find(status: "QUEUED").first
      end

      def find_recent_scans(ip, port, seconds_old)
        results = []

        # TODO: make this part of the query so it doesn't turn into a perf issue
        @collection.find("target" => ip, "port" => port).each do |result|
          if Time.now - result["_id"].generation_time < seconds_old
            results << result
          end
        end

        return results
      end

      def find_scans(ip, port)
        @collection.find("target" => ip, "port" => port)
      end
    end
  end
end
