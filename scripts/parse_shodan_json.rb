require 'json'

json_file = File.open(ARGV[0])


json_file.each_line do |line|
  parsed_json = JSON.parse(line)
  
  if parsed_json["ip_str"]
  	puts parsed_json["ip_str"].chomp
  end
end