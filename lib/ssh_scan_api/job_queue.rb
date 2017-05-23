require 'set'

module SSHScan
  class JobQueue
    def initialize
      @queue = Set.new
    end

    # @param [String] a socket we want to scan (Example: "192.168.1.1:22")
    # @return [nil]
    def add(socket)
      @queue << socket
    end

    def each
      @queue.each do |item|
        yield item
      end
    end

    # @return [String] a socket we want to scan (Example: "192.168.1.1:22")
    def next
      return nil if @queue.empty?
      next_item = @queue.first
      @queue.delete(next_item)
      return next_item
    end

    # @return [FixNum] the number of jobs in the JobQueue
    def size
      @queue.size
    end
  end
end
