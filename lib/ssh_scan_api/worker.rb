require 'ssh_scan/scan_engine'
require 'ssh_scan_api/version'
require 'ssh_scan_api/models/scan'
require 'logger'
require 'yaml'

class SSHScan::Worker
  def initialize()
    @worker_id = SecureRandom.uuid
    @log = Logger.new(STDOUT)
    @fingerprint_database_path = File.join(File.dirname(__FILE__),"../../data/fingerprints.yml")
    @policy_path = File.join(File.dirname(__FILE__),"../../config/policies/mozilla_modern.yml")
    @poll_interval = 1
  end

  def set_environment(environment)
    ActiveRecord::Base.logger = Logger.new(STDOUT)

    config = YAML.load_file(File.join(File.dirname(__FILE__),"../../config/database.yml"))

    # Allow environmental variable override on environment
    if ENV['SSHSCANDATABASEENV']
      environment = ENV['SSHSCANDATABASEENV']
    end

    case environment
    when "test"
      ActiveRecord::Base.establish_connection(config["test"])
    when "development"
      ActiveRecord::Base.establish_connection(config["development"])
    when "production"
      ActiveRecord::Base.establish_connection(config["production"])
    else
      raise "Unsupported environment specified, acceptable environments are test, development, or production"
    end
  end

  def do_work
    scan = SSHScan::Scan.find_by("state": "QUEUED")

    # If work to do, then do it
    if scan
      scan.state = "RUNNING"
      scan.worker_id = @worker_id
      scan.save

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

      if results.first["compliance"]
        scan.grade = results.first["compliance"]["grade"]
      end
      
      scan.raw_scan = results.first.to_json
      scan.save
    else
      @log.info("No work available")
      sleep @poll_interval
    end
  end

  def run!
    loop do
      do_work
    end
  end
end