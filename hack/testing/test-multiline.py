import sys
import json

obj = json.loads(sys.stdin.read())

for dd in obj['hits']['hits']:
    if dd['_score'] < 1.0:
        print "ignoring spurious hit"
        continue
    # TODO: check for the other fields
    if not (dd['_source']['message'] == 'START\nMultiline 1\nMultiline 1\n'
        or dd['_source']['message'] == 'START\nMultiline 2\n'):
        print 'Error: message not aggregated correctly: [%s]' % (dd['_source']['message'])
        sys.exit(1)

print 'Success: record contains all of the expected fields/values'
sys.exit(0)
