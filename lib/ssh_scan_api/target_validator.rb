require 'ssh_scan_api/constants'


module SSHScan
  module Api
    class TargetValidator
      def initialize(config = {})
        @invalid_target_regexes = config["invalid_target_regexes"] || SSHScan::Api::Constants::INVALID_TARGET_REGEXES
        @invalid_target_strings = config["invalid_target_strings"] || SSHScan::Api::Constants::INVALID_TARGET_STRINGS
        @valid_char_list = config["valid_char_list"] || SSHScan::Api::Constants::VALID_CHAR_LIST
      end

      def invalid_char?(target_string)
        target_string.chars.each do |char|
          return true unless @valid_char_list.include?(char)
        end

        return false
      end

      def invalid?(target_string)
        !valid?(target_string)
      end

      def valid?(target_string)
        return false unless target_string.is_a?(String)
        return false if target_string.empty?
        return false if invalid_char?(target_string)

        if @invalid_target_regexes.is_a?(::Array)
          @invalid_target_regexes.each do |invalid_regex|
            if target_string.match(Regexp.new(invalid_regex))
              return false
            end
          end
        end

        if @invalid_target_strings.is_a?(::Array)
          @invalid_target_strings.each do |invalid_string|
            if target_string.chomp.downcase == invalid_string.chomp.downcase
              return false
            end
          end
        end

        return true        
      end
    end
  end
end
