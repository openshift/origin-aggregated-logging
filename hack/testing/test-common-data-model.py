import sys
import json

test = sys.argv[1]
check_for_empty = True
if len(sys.argv) > 1:
    check_for_empty = False

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

if check_for_empty and empty(obj):
    print "Error: input has one or more empty fields"
    sys.exit(1)

test2match = {
    "test1": {"undefined1": "undefined1",
              "undefined11": 1111,
              "undefined12": True,
              "undefined2": {
                  "undefined2": "undefined2",
                  "undefined22": 2222,
                  "undefined23": False
              },
              "undefined4": "undefined4",
              "undefined5": "undefined5"
    },
    "test2": {"undefined":
              {"undefined1": "undefined1",
               "undefined11": 1111,
               "undefined12": True,
               "undefined2": {
                   "undefined2": "undefined2",
                   "undefined22": 2222,
                   "undefined23": False
               },
               "undefined4": "undefined4",
               "undefined5": "undefined5"
              }
    },
    "test3": {"undefined":
              {"undefined1": "undefined1",
               "undefined11": 1111,
               "undefined12": True,
               "undefined2": {
                   "undefined2": "undefined2",
                   "undefined22": 2222,
                   "undefined23": False
               }
              },
              "undefined4": "undefined4",
              "undefined5": "undefined5"
    },
    "test4": {"myname":
              {"undefined1": "undefined1",
               "undefined11": 1111,
               "undefined12": True,
               "undefined2": {
                   "undefined2": "undefined2",
                   "undefined22": 2222,
                   "undefined23": False
               }
              },
              "undefined4": "undefined4",
              "undefined5": "undefined5"
    },
    "test5": {"myname":
              {"undefined1": "undefined1",
               "undefined11": 1111,
               "undefined12": True,
               "undefined2": {
                   "undefined2": "undefined2",
                   "undefined22": 2222,
                   "undefined23": False
               }
              },
              "undefined4": "undefined4",
              "undefined5": "undefined5",
              "empty1": "",
              "undefined3": {"": ""}
    }
}

for dd in obj['hits']['hits']:
    if dd['_score'] < 1.0:
        print "ignoring spurious hit"
        continue
    if not '@timestamp' in dd['_source']:
        print "Error: missing @timestamp field"
        sys.exit(1)
    match = test2match[test]
    for xx in match:
        if xx not in dd['_source']:
            print "Error: input does not have the field [%s]" % xx
            sys.exit(1)
        if not match[xx] == dd['_source'][xx]:
            print "Error: input field [%s] expected value [%s] does not match actual value [%s]" % (xx, match[xx], dd['_source'][xx])
            sys.exit(1)

sys.exit(0)
