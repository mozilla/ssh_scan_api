import datetime
import logging

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

def run(event, context):
    current_time = datetime.datetime.now().time()
    name = context.function_name
    logger.info("Your cron function " + name + " ran at " + str(current_time))

    import requests

    message = ""

    try
	  response = requests.get("https://sshscan.rubidus.com/")

	  if response.status_code != 200
	    message = "Got non-200 response from SSH Scan API base route"
	  elif response.text != "See API documentation here: https://github.com/mozilla/ssh_scan_api/wiki/ssh_scan-Web-API"
	    message = "Got unexpected content from SSH Scan API base route"

	except requests.exceptions.RequestException
	  message = "Unable to connect to SSH Scan API"

	#TODO: Send message somewhere (maybe pushover), if it's set (to start, we'll just report to log for dev/testing purposes)
	if message
	  logger.info("Failing State: " + message + " " + str(current_time))
	else
   	  logger.info("Passing State: " + message + " " + str(current_time))