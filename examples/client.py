from __future__ import print_function

import requests
import json
import time

api_server = "https://sshscan.rubidus.com"

print("[+] Submitting scan request for ssh.mozilla.com")
resp = requests.post(api_server + "/api/v1/scan?target=ssh.mozilla.com")
print("[+] Got %s %s %s" % (resp.status_code, resp.reason, resp.text))

resp_json = json.loads(resp.text)
res_url = "%s/api/v1/scan/results?uuid=%s" % (api_server, resp_json["uuid"])

while True:
    print("[+] Checking for scan results")
    scan_results = requests.get(res_url)
    scan_results_json = json.loads(scan_results.text)
    if 'ssh_scan_version' in scan_results_json:
        print(scan_results_json)
        exit()
    else:
        print("[+] Backing off for a sec to let scan to complete")
        time.sleep(1)
