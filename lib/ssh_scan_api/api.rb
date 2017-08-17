require 'sinatra/base'
require 'sinatra/namespace'
require 'json'
require 'haml'
require 'secure_headers'
require 'thin'
require 'securerandom'
require 'ssh_scan'
require 'ssh_scan_api/database'
require 'ssh_scan_api/target_validator'

module SSHScan
  class API < Sinatra::Base
    if ENV['RACK_ENV'] == 'test'
      configure do
        set :authentication, false
        config_file = File.join(Dir.pwd, "./config/api/config.yml")
        opts = YAML.load_file(config_file)
        opts["config_file"] = config_file
        set :db, SSHScan::Database.from_hash(opts)
        set :target_validator, SSHScan::TargetValidator.new()
        set :environment, :production
        set :allowed_ports, [22]
      end
    end

    # Configure all the secure headers we want to use
    use SecureHeaders::Middleware
    SecureHeaders::Configuration.default do |config|
      config.cookies = {
        secure: true, # mark all cookies as "Secure"
        httponly: true, # mark all cookies as "HttpOnly"
      }
      config.hsts = "max-age=31536000; includeSubdomains; preload"
      config.x_frame_options = "DENY"
      config.x_content_type_options = "nosniff"
      config.x_xss_protection = "1; mode=block"
      config.x_download_options = "noopen"
      config.x_permitted_cross_domain_policies = "none"
      config.referrer_policy = "no-referrer"
      config.csp = {
        default_src: ["'none'"],
        frame_ancestors: ["'none'"],
        upgrade_insecure_requests: true, # see https://www.w3.org/TR/upgrade-insecure-requests/
      }
    end

    register Sinatra::Namespace

    before do
      headers "Access-Control-Allow-Methods" => "GET, POST"
      headers "Access-Control-Allow-Origin" => "*"
      headers "Access-Control-Max-Age" => "86400"
      headers "Cache-control" => "no-store"
      headers "Pragma" => "no-cache"
      headers "Server" => "ssh_scan_api"
    end

    # Custom 404 handling
    not_found do
      content_type "text/plain"
      "Invalid request, see API documentation here: \
https://github.com/mozilla/ssh_scan_api/wiki/ssh_scan-Web-API\n"
    end

    get '/' do
      content_type "text/plain"
      "See API documentation here: \
https://github.com/mozilla/ssh_scan_api/wiki/ssh_scan-Web-API\n"
    end

    get '/robots.txt' do
      content_type "text/plain"
      "User-agent: *\nDisallow: /\n"
    end

    get '/contribute.json' do
      content_type :json
      SSHScan::Constants::CONTRIBUTE_JSON.to_json
    end

    get '/__version__' do
      {
        :ssh_scan_version => SSHScan::VERSION,
        :api_version => SSHScan::API_VERSION,
      }.to_json
    end

    namespace "/api/v1" do
      before do
        content_type :json
      end

      post '/scan' do
        # Require authentication for this route only when auth is enabled
        authenticated? if settings.authentication == true
        
        target = params["target"]
        port = params["port"] ? params["port"].to_i : 22
        socket = {"target" => target, "port" => port}

        # Let's stop garbage targets in their tracks
        if settings.target_validator.invalid?(target)
          return {"error" => "invalid target"}.to_json
        elsif !target.ip_addr? && !target.fqdn?
          return {"error" => "invalid target"}.to_json
        end

        # Let's make sure we only scan ports we're allowed to scan
        if !settings.allowed_ports.include?(port)
          return {"error" => "invalid port"}.to_json 
        end

        # Check DB to see if we have a recent scans (<= 5 min ago) for this target
        results = settings.db.find_recent_scans(target, port, 300)

        # If we have recent results, return that UUID, if not assign a new one
        if results.any?
          uuid = results.first["uuid"]
        else
          uuid = SecureRandom.uuid
          settings.db.queue_scan(uuid, socket)
        end

        {
          uuid: uuid
        }.to_json
      end

      get '/scan/results' do
        # Require authentication for this route only when auth is enabled
        authenticated? if settings.authentication == true

        uuid = params[:uuid]

        # If we don't get a uuid, we don't know what scan to pick up
        return {"error" => "no uuid specified"}.to_json if uuid.nil? || uuid.empty?

        result = settings.db.get_scan(uuid)

        return {"error" => "invalid uuid specified"}.to_json if result.nil?

        case result["status"]
        when "QUEUED"
          return {"status" => "QUEUED"}.to_json
        when "ERRORED"
          return {"status" => "ERRORED"}.to_json
        when "RUNNNING"
          return {"status" => "RUNNNING"}.to_json
        when "COMPLETED"
          result["scan"]["status"] = "COMPLETED"
          return result["scan"].to_json
        else
          return {"scan" => "UNKNOWN"}.to_json
        end
      end

      get '/work' do
        # Always require authentication for this route
        authenticated?

        worker_id = params[:worker_id]

        doc = settings.db.next_scan_in_queue

        if doc.nil?
          return {"work" => false}.to_json
        else
          settings.db.run_scan(doc["uuid"])
          socket = [doc["target"],doc["port"]].join(":")
          {
            "work" => {
              "uuid" => doc["uuid"],
              "sockets" => [socket]
            }
          }.to_json
        end
      end

      post '/work/results/:worker_id/:uuid' do
        # Always require authentication for this route
        authenticated?

        worker_id = params['worker_id']
        uuid = params['uuid']
        result = JSON.parse(request.body.first).first
        socket = {}
        socket["target"] = result['ip']
        socket["port"] = result['port']

        if worker_id.empty? || uuid.empty?
          return {"accepted" => "false"}.to_json
        end

        if result["error"]
          settings.db.error_scan(uuid, worker_id, result)
        else
          settings.db.complete_scan(uuid, worker_id, result)
        end
      end

      get '/stats' do
        {
          "SCAN_STATES" => {
            "QUEUED" => settings.db.queue_count,
            "RUNNING" => settings.db.run_count,
            "ERRORED" => settings.db.error_count,
            "COMPLETED" => settings.db.complete_count,
          },
          "QUEUED_MAX_AGE" => settings.db.queued_max_age,
          "GRADE_REPORT" => settings.db.grade_report
        }.to_json
      end

      get '/__lbheartbeat__' do
        {
          :status  => "OK",
          :message => "Keep sending requests. I am still alive."
        }.to_json
      end
    end

    def authenticated?
      token = request.env['HTTP_SSH_SCAN_AUTH_TOKEN']

      # If a token is not provided, only localhost can proceed
      if token.nil? && request.ip != "127.0.0.1"
        halt '{"error" : "authentication failure"}'
      end

      # If a token is provided, it must be valid to proceed
      if token && settings.authenticator.valid_token?(token) == false
        halt '{"error" : "authentication failure"}'
      end
    end

    def self.run!(options = {}, &block)
      set options

      configure do
        enable :logging
        set :bind, ENV['sshscan.api.bind'] || options["bind"] || '127.0.0.1'
        set :server, "thin"
        set :logger, Logger.new(STDOUT)
        set :db, SSHScan::Database.from_hash(options)
        set :target_validator, SSHScan::TargetValidator.new(options["config_file"])
        set :results, {}
        set :stats, SSHScan::Stats.new
        set :authentication, options["authentication"]
        set :authenticator, SSHScan::Authenticator.from_config_file(
          options["config_file"]
        )
        set :allowed_ports, options["allowed_ports"]
        set :protection, false
      end

      super do |server|
        # No SSL on app, SSL termination happens in nginx for a prod deployment
        server.ssl = false
      end
    end
  end
end
