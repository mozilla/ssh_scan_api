import datetime
import logging

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

def run(event, context):
    current_time = datetime.datetime.now().time()
    name = context.function_name
    logger.info("Your cron function " + name + " ran at " + str(current_time))
    #TODO
    # 1.) Make a get request(s) to the SSH API endpoint and see if it's still running
    # 2.) If it's still running, do nothing, if it is, then pop an alert (like a pushover notification or something)
