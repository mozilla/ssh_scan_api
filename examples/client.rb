require 'net/http'
require 'uri'
require 'json'

target = ARGV[0] || "ssh.mozilla.com"
#api_server = URI.parse("https://sshscan.rubidus.com")
api_server = URI.parse("http://127.0.0.1:8000")


warn "[+] Submitting scan request for #{target}"
response = Net::HTTP.post_form(api_server + "/api/v1/scan", {"target" => target})

warn "[+] Got #{response.code} #{response.body}"
resp = JSON.parse(response.body)

loop do
  warn "[+] Checking for scan results"
  result_uri = api_server + ("/api/v1/scan/results?uuid=" + resp["uuid"])
  scan_status = Net::HTTP.get_response(result_uri)

  scan_results = JSON.parse(scan_status.body)

  if scan_results["ssh_scan_version"]
    puts scan_results.to_json
    exit
  else
    warn "[+] Backing off for a half sec to let scan to complete"
    sleep 0.5
  end
end