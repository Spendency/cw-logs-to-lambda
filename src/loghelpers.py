"""Collection of functions to deal with CloudWatch logs."""
import base64
import gzip
import json
from datetime import datetime

ID = 'id'
TIMESTAMP = 'timestamp'
MESSAGE = 'message'


def extract_log_events(event):
    """Decode and decompress log data."""
    log_data = event['awslogs']['data']
    compressed_data = base64.b64decode(log_data)
    decompressed_data = gzip.decompress(compressed_data)
    json_data = json.loads(decompressed_data)
    log_stream = json_data['logStream']
    log_events = json_data['logEvents']
    return (log_stream, log_events)


def condense_log_events(log_stream, log_events):
    """Condense log events into single strings. expects list of dicts."""
    condensed_events = []
    for event in log_events:
        event_datetime = datetime.fromtimestamp(event['timestamp'] / 1000)
        message = "{} | {} | {}".format(log_stream, event_datetime, event['message'])
        condensed_events.append(message)

    return condensed_events
