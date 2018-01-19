require 'ssh_scan_api/database/postgres'

module SSHScan
  class Database
    attr_reader :database

    # @param [SSHScan::Database::Postgres] database
    def initialize(database)
      @database = database
    end

    # @param [Hash] opts
    # @return [SSHScan::Database]
    def self.from_hash(opts)
      database_options = opts["database"]
      database = SSHScan::DB::Postgres.from_hash(database_options)
      SSHScan::Database.new(database)
    end

    def run_count
      @database.run_count
    end

    def queue_count
      @database.queue_count
    end

    def batch_queue_count
      @database.batch_queue_count
    end

    def error_count
      @database.error_count
    end

    def queued_max_age
      @database.queued_max_age
    end

    def complete_count
      @database.complete_count
    end

    def total_count
      @database.total_count
    end

    def run_scan(uuid)
      @database.run_scan(uuid)
    end

    def get_scan(uuid)
      @database.get_scan(uuid)
    end

    def get_scan_state(uuid)
      @database.get_scan_state(uuid)
    end

    def auth_method_report
      @database.auth_method_report
    end

    def grade_report
      @database.grade_report
    end

    def queue_scan(target, port, uuid)
      @database.queue_scan(target, port, uuid)
    end

    def batch_queue_scan(target, port, uuid)
      @database.batch_queue_scan(target, port, uuid)
    end

    def complete_scan(uuid, worker_id, result)
      @database.complete_scan(uuid, worker_id, result)
    end

    def error_scan(uuid, worker_id, result)
      @database.error_scan(uuid, worker_id, result)
    end

    def next_scan_in_batch_queue
      @database.next_scan_in_batch_queue
    end

    def next_scan_in_queue
      @database.next_scan_in_queue
    end

    def get_work(uuid)
      @database.get_work(uuid)
    end

    def find_recent_scans(ip, port, test_flag = false)
      @database.find_recent_scans(ip, port, test_flag)
    end

    def find_scans(ip, port)
      @database.find_scans(ip, port)
    end

  end
end
