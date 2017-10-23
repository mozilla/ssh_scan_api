module SSHScan
  class Queue
  	def initialize(config = {})
  	  @server = config("server")
  	  @port = config("port")
  	  @channel = "ssh_scan_work"
  	  @
  	end

    def self.from_hash(opts)
      database_options = opts["rabbitmq"]
      SSHScan::Queue.new(database_options)
    end

    def send
      #send work to channel
    end

    def receive
      #receive work from channel
    end
  end
end
