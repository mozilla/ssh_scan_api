require 'ssh_scan/scan_engine'
require 'ssh_scan_api/version'
require 'ssh_scan_api/models/scan'
require 'logger'



class SSHScan::Worker
  def initialize()
    @worker_id = SecureRandom.uuid
    @log = Logger.new(STDOUT)
    @fingerprint_database_path = File.join(File.dirname(__FILE__),"../../data/fingerprints.yml")
    @policy_path = File.join(File.dirname(__FILE__),"../../config/policies/mozilla_modern.yml")
    @poll_interval = 1
  end

  def setup_db_connection
    ActiveRecord::Base.establish_connection({adapter: "sqlite3", database: "foo.sqlite3"})
    ActiveRecord::Base.logger = Logger.new(STDOUT)
  end

  def do_work
    scan = SSHScan::Scan.find_by("state": "QUEUED")

    # If work to do, then do it
    if scan
      @log.info("Starting Scan: #{scan.scan_id}")
      options = {
        "sockets" => [[scan.target,scan.port.to_s].join(":")],
        "fingerprint_database" => @fingerprint_database_path,
        "policy" => @policy_path,
        "timeout" => 5,
      }

      scan_engine = SSHScan::ScanEngine.new
      results = scan_engine.scan(options)

      scan.state = "COMPLETED"
      scan.worker_id = @worker_id
      scan.raw_scan = results.first.to_json
      scan.save
    else
      @log.info("No work available")
    end
  end

  def run!
    setup_db_connection
    
    loop do
      do_work
      sleep @poll_interval
    end
  end
end