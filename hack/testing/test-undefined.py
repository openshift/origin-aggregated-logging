import sys
import json

def empty(thing):
    if isinstance(thing,str) and not thing:
        return True
    if isinstance(thing,unicode) and not thing:
        return True
    items = []
    if isinstance(thing,list):
        if not thing:
            return True
        items = thing
    if isinstance(thing,dict):
        if not thing:
            return True
        items = thing.values()
    for ii in items:
        if empty(ii):
            return True
    return False

obj = json.loads(sys.stdin.read())

if empty(obj):
    print "Error: input has one or more empty fields"
    sys.exit(1)

for dd in obj['hits']['hits']:
    if dd['_score'] < 1.0:
        print "ignoring spurious hit"
        continue
    match = {"undefined1": "undefined1",
             "undefined2": {
                 "undefined2": "undefined2"
             }
    }
    if not dd['_source'].get('undefined', None) == match:
        print "Error: input does not have the 'undefined' field with the correct values"
        sys.exit(1)

sys.exit(0)
