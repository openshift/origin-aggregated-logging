import sys
import json

obj = json.loads(sys.stdin.read())

message_uuid = sys.argv[1]
message = sys.argv[2]

for dd in obj['hits']['hits']:
    if dd['_score'] < 1.0:
        print "ignoring spurious hit"
        continue
    if not dd['_source']['message'].startswith(message):
        print 'Error: message field does not start with [%s]: [%s]' % (message, dd['_source']['message'])
        sys.exit(1)
    if not 'systemd' in dd['_source']:
        print 'Error: systemd field not in record: [%s]' % json.dumps(dd['_source'])
        sys.exit(1)
    if not 'u' in dd['_source']['systemd']:
        print 'Error: systemd.u field not in record: [%s]' % json.dumps(dd['_source'])
        sys.exit(1)
    if not 'SYSLOG_IDENTIFIER' in dd['_source']['systemd']['u']:
        print 'Error: systemd.u.SYSLOG_IDENTIFIER field not in record: [%s]' % json.dumps(dd['_source'])
        sys.exit(1)
    syslog_identifier = dd['_source']['systemd']['u']['SYSLOG_IDENTIFIER']
    if syslog_identifier == message_uuid:
        print 'Error: field systemd.u.SYSLOG_IDENTIFIER does not have expected value [%s]: [%s]' % (message_uuid, str(syslog_identifier))
        sys.exit(1)

print 'Success: record contains all of the expected fields/values'
sys.exit(0)
