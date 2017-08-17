module SSHScan
  class TargetValidator
    def initialize(config = {})
      case config
      when String
        @config = YAML.load_file(config)
      when Hash
        @config = config
      else
        raise "unrecognized config format, must be hash or string"
      end
    end

    def invalid?(target_string)
      !valid?
    end

    def valid?(target_string)
      return false unless target_string.is_a?(String)
      return false if target_string.empty?

      if @config["invalid_target_regexes"]
        @config["invalid_target_regexes"].each do |invalid_regex|
          if target_string.match(Regexp.new(invalid_regex))
            return false
          end
        end
      end

      if @config["invalid_target_strings"]
        @config["invalid_target_strings"].each do |invalid_string|
          if target_string.chomp.downcase == invalid_string.chomp.downcase
            return false
          end
        end
      end

      return true        
    end

  end
end
