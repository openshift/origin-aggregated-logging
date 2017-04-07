import sys
import json

obj = json.loads(sys.stdin.read())

uuid = sys.argv[1]

matchfieldsvalues = {
    'statusCode': 404,
    'type': 'response',
    'method': 'get'
}

for dd in obj['hits']['hits']:
    if dd['_score'] < 1.0:
        print "ignoring spurious hit"
        continue
    match = 'GET /%s 404 ' % uuid
    if not dd['_source']['message'].startswith(match):
        print 'Error: message field does not start with [%s]: [%s]' % (match, dd['_source']['message'])
        sys.exit(1)
    for field,value in matchfieldsvalues.iteritems():
        if not field in dd['_source']:
            print 'Error: %s field not in record: [%s]' % (field, json.dumps(dd['_source']))
            sys.exit(1)
        if not dd['_source'][field] == value:
            print 'Error: field %s does not have expected %s value: [%s]' % (field, str(value), str(dd['_source'][field]))
            sys.exit(1)

print 'Success: record contains all of the expected fields/values'
sys.exit(0)
