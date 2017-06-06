require 'ssh_scan_api/database/mongo'

module SSHScan
  class Database
    attr_reader :database

    # @param [SSHScan::Database::MongoDb, SSHScan::Database::SQLite] database
    def initialize(database)
      @database = database
    end

    # @param [Hash] opts
    # @return [SSHScan::Database]
    def self.from_hash(opts)
      database_options = opts["database"]

      # Figure out what database object to load
      case database_options["type"]
      when "mongodb"
        database = SSHScan::DB::MongoDb.from_hash(database_options)
      else
        raise "Database type of #{database_options[:type].class} not supported"
      end

      SSHScan::Database.new(database)
    end

    def run_count
      @database.run_count
    end

    def queue_count
      @database.queue_count
    end

    def error_count
      @database.error_count
    end

    def complete_count
      @database.complete_count
    end

    def run_scan(uuid)
      @database.run_scan(uuid)
    end

    def complete_scan(uuid, worker_id, result)
      @database.complete_scan(uuid, worker_id, result)
    end

    def error_scan(uuid, worker_id, result)
      @database.error_scan(uuid, worker_id, result)
    end

    def next_scan_in_queue
      @database.next_scan_in_queue
    end

    def find_recent_scans(ip, port, seconds_old)
      @database.find_recent_scans(ip, port, seconds_old)
    end

    def find_scans(ip, port)
      @database.find_scans(ip, port)
    end

  end
end
