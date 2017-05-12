from __future__ import print_function

import requests
import json
import time

api_server = "https://sshscan.rubidus.com"

print("[+] Submitting scan request for ssh.mozilla.com")
submit_response = requests.post(api_server + "/api/v1/scan?target=ssh.mozilla.com")
print("[+] Got %s %s %s" % (submit_response.status_code, submit_response.reason, submit_response.text))

submit_response_json = json.loads(submit_response.text)
results_url = "%s/api/v1/scan/results?uuid=%s" % (api_server,submit_response_json["uuid"])

while True:
  print("[+] Checking for scan results")
  scan_results = requests.get(results_url)
  scan_results_json = json.loads(scan_results.text)
  if 'ssh_scan_version' in scan_results_json:
    print(scan_results_json)
    exit()
  else:
    print("[+] Backing off for a sec to let scan to complete")
    time.sleep(1)
