# added 2015-05-05 by Rainer Gerhards
# This file is part of the liblognorm project, released under ASL 2.0
. $srcdir/exec.sh

test_def $0 "CEF parser"
add_rule 'rule=:%f:cef%'

# fabricated tests to test specific functionality
execute 'CEF:0|Vendor|Product|Version|Signature ID|some name|Severity| aa=field1 bb=this is a value cc=field 3'
assert_output_json_eq '{ "f": { "DeviceVendor": "Vendor", "DeviceProduct": "Product", "DeviceVersion": "Version", "SignatureID": "Signature ID", "Name": "some name", "Severity": "Severity", "Extensions": { "aa": "field1", "bb": "this is a value", "cc": "field 3" } } }'

execute 'CEF:0|Vendor|Product\|1\|\\|Version|Signature ID|some name|Severity| aa=field1 bb=this is a name\=value cc=field 3'
assert_output_json_eq '{ "f": { "DeviceVendor": "Vendor", "DeviceProduct": "Product|1|\\", "DeviceVersion": "Version", "SignatureID": "Signature ID", "Name": "some name", "Severity": "Severity", "Extensions": { "aa": "field1", "bb": "this is a name=value", "cc": "field 3" } } }'

execute 'CEF:0|Vendor|Product|Version|Signature ID|some name|Severity| aa=field1 bb=this is a \= value cc=field 3'
assert_output_json_eq '{ "f": { "DeviceVendor": "Vendor", "DeviceProduct": "Product", "DeviceVersion": "Version", "SignatureID": "Signature ID", "Name": "some name", "Severity": "Severity", "Extensions": { "aa": "field1", "bb": "this is a = value", "cc": "field 3" } } }'

execute 'CEF:0|Vendor|Product|Version|Signature ID|some name|Severity|'
assert_output_json_eq '{ "f": { "DeviceVendor": "Vendor", "DeviceProduct": "Product", "DeviceVersion": "Version", "SignatureID": "Signature ID", "Name": "some name", "Severity": "Severity", "Extensions": { } } }'

execute 'CEF:0|Vendor|Product|Version|Signature ID|some name|Severity| name=value'
assert_output_json_eq '{ "f": { "DeviceVendor": "Vendor", "DeviceProduct": "Product", "DeviceVersion": "Version", "SignatureID": "Signature ID", "Name": "some name", "Severity": "Severity", "Extensions": { "name": "value" } } }'

execute 'CEF:0|Vendor|Product|Version|Signature ID|some name|Severity| name=val\nue' # embedded LF
assert_output_json_eq '{ "f": { "DeviceVendor": "Vendor", "DeviceProduct": "Product", "DeviceVersion": "Version", "SignatureID": "Signature ID", "Name": "some name", "Severity": "Severity", "Extensions": { "name": "val\nue" } } }'

execute 'CEF:0|Vendor|Product|Version|Signature ID|some name|Severity| n,me=value' #invalid punctuation in extension
assert_output_json_eq '{ "originalmsg": "CEF:0|Vendor|Product|Version|Signature ID|some name|Severity| n,me=value", "unparsed-data": "CEF:0|Vendor|Product|Version|Signature ID|some name|Severity| n,me=value" }'

execute 'CEF:0|Vendor|Product|Version|Signature ID|some name|Severity| name=v\alue' #invalid escape in extension
assert_output_json_eq '{ "originalmsg": "CEF:0|Vendor|Product|Version|Signature ID|some name|Severity| name=v\\alue", "unparsed-data": "CEF:0|Vendor|Product|Version|Signature ID|some name|Severity| name=v\\alue" }'

execute 'CEF:0|V\endor|Product|Version|Signature ID|some name|Severity| name=value' #invalid escape in header
assert_output_json_eq '{ "originalmsg": "CEF:0|V\\endor|Product|Version|Signature ID|some name|Severity| name=value", "unparsed-data": "CEF:0|V\\endor|Product|Version|Signature ID|some name|Severity| name=value" }'

execute 'CEF:0|Vendor|Product|Version|Signature ID|some name|Severity| ' # single trailing space - valid
assert_output_json_eq '{ "f": { "DeviceVendor": "Vendor", "DeviceProduct": "Product", "DeviceVersion": "Version", "SignatureID": "Signature ID", "Name": "some name", "Severity": "Severity", "Extensions": { } } }'

execute 'CEF:0|Vendor|Product|Version|Signature ID|some name|Severity|   ' # multiple trailing spaces - invalid
assert_output_json_eq '{ "originalmsg": "CEF:0|Vendor|Product|Version|Signature ID|some name|Severity|   ", "unparsed-data": "CEF:0|Vendor|Product|Version|Signature ID|some name|Severity|   " }'

execute 'CEF:0|Vendor'
assert_output_json_eq '{ "originalmsg": "CEF:0|Vendor", "unparsed-data": "CEF:0|Vendor" }'

execute 'CEF:1|Vendor|Product|Version|Signature ID|some name|Severity| aa=field1 bb=this is a \= value cc=field 3'
assert_output_json_eq '{ "originalmsg": "CEF:1|Vendor|Product|Version|Signature ID|some name|Severity| aa=field1 bb=this is a \\= value cc=field 3", "unparsed-data": "CEF:1|Vendor|Product|Version|Signature ID|some name|Severity| aa=field1 bb=this is a \\= value cc=field 3" }'

execute ''
assert_output_json_eq '{ "originalmsg": "", "unparsed-data": "" }'

# finally, a use case from practice
execute 'CEF:0|ArcSight|ArcSight|10.0.0.15.0|rule:101|FOO-UNIX-Bypassing Golden Host-Direct Root Connection Attempt|High| eventId=24934046519 type=2 mrt=8888882444085 sessionId=0 generatorID=34rSQWFOOOCAVlswcKFkbA\=\= categorySignificance=/Normal categoryBehavior=/Execute/Query categoryDeviceGroup=/Application categoryOutcome=/Success categoryObject=/Host/Application modelConfidence=0 severity=0 relevance=10 assetCriticality=0 priority=2 art=1427882454263 cat=/Detection/FOO/UNIX/Direct Root Connection Attempt deviceSeverity=Warning rt=1427881661000 shost=server.foo.bar src=10.0.0.1 sourceZoneID=MRL4p30sFOOO8panjcQnFbw\=\= sourceZoneURI=/All Zones/FOO Solutions/Server Subnet/UK/PAR-WDC-12-CELL5-PROD S2U 1 10.0.0.1-10.0.0.1 sourceGeoCountryCode=GB sourceGeoLocationInfo=London slong=-0.90843 slat=51.9039 dhost=server.foo.bar dst=10.0.0.1 destinationZoneID=McFOOO0sBABCUHR83pKJmQA\=\= destinationZoneURI=/All Zones/FOO Solutions/Prod/AMERICAS/FOO 10.0.0.1-10.0.0.1 duser=johndoe destinationGeoCountryCode=US destinationGeoLocationInfo=Jersey City dlong=-90.0435 dlat=30.732 fname=FOO-UNIX-Bypassing Golden Host-Direct Root Connection Attempt filePath=/All Rules/Real-time Rules/ACBP-ACCESS CONTROL and AUTHORIZATION/FOO/Unix Server/FOO-UNIX-Bypassing Golden Host-Direct Root Connection Attempt fileType=Rule ruleThreadId=NQVtdFOOABDrKsmLWpyq8g\=\= cs2=<Resource URI\=""/All Rules/Real-time Rules/FOO-ACCESS CONTROL and AUTHORIZATION/FOO/Unix Server/FOO-UNIX-Bypassing Golden Host-Direct Root Connection Attempt"" ID\=""5lzFOO--RTSN-TESTQ\=\=""/> flexString2=DC0001-988 locality=1 cs2Label=Configuration Resource ahost=foo.bar agt=10.0.0.1 av=10.0.0.12 atz=Europe/Berlin aid=34rSQWFOOOBCAVlswcKFkbA\=\= at=superagent_ng dvchost=server.foo.bar dvc=10.0.0.1 deviceZoneID=Mbb8pFOOODol1dBKdURJA\=\= deviceZoneURI=/All Zones/FOO Solutions/Prod/GERMANY/FOO US2 Class6 A 508 10.0.0.1-10.0.0.1 dtz=Europe/Berlin deviceFacility=Rules Engine eventAnnotationStageUpdateTime=1427882444192 eventAnnotationModificationTime=1427882444192 eventAnnotationAuditTrail=1,1427453188050,root,Queued,,,,\n eventAnnotationVersion=1 eventAnnotationFlags=0 eventAnnotationEndTime=1427881661000 eventAnnotationManagerReceiptTime=1427882444085 _cefVer=0.1 ad.arcSightEventPath=3VcygrkkBABCAYFOOLlU13A\=\= baseEventIds=24934003731"'
assert_output_json_eq '{ "f": { "DeviceVendor": "ArcSight", "DeviceProduct": "ArcSight", "DeviceVersion": "10.0.0.15.0", "SignatureID": "rule:101", "Name": "FOO-UNIX-Bypassing Golden Host-Direct Root Connection Attempt", "Severity": "High", "Extensions": { "eventId": "24934046519", "type": "2", "mrt": "8888882444085", "sessionId": "0", "generatorID": "34rSQWFOOOCAVlswcKFkbA==", "categorySignificance": "\/Normal", "categoryBehavior": "\/Execute\/Query", "categoryDeviceGroup": "\/Application", "categoryOutcome": "\/Success", "categoryObject": "\/Host\/Application", "modelConfidence": "0", "severity": "0", "relevance": "10", "assetCriticality": "0", "priority": "2", "art": "1427882454263", "cat": "\/Detection\/FOO\/UNIX\/Direct Root Connection Attempt", "deviceSeverity": "Warning", "rt": "1427881661000", "shost": "server.foo.bar", "src": "10.0.0.1", "sourceZoneID": "MRL4p30sFOOO8panjcQnFbw==", "sourceZoneURI": "\/All Zones\/FOO Solutions\/Server Subnet\/UK\/PAR-WDC-12-CELL5-PROD S2U 1 10.0.0.1-10.0.0.1", "sourceGeoCountryCode": "GB", "sourceGeoLocationInfo": "London", "slong": "-0.90843", "slat": "51.9039", "dhost": "server.foo.bar", "dst": "10.0.0.1", "destinationZoneID": "McFOOO0sBABCUHR83pKJmQA==", "destinationZoneURI": "\/All Zones\/FOO Solutions\/Prod\/AMERICAS\/FOO 10.0.0.1-10.0.0.1", "duser": "johndoe", "destinationGeoCountryCode": "US", "destinationGeoLocationInfo": "Jersey City", "dlong": "-90.0435", "dlat": "30.732", "fname": "FOO-UNIX-Bypassing Golden Host-Direct Root Connection Attempt", "filePath": "\/All Rules\/Real-time Rules\/ACBP-ACCESS CONTROL and AUTHORIZATION\/FOO\/Unix Server\/FOO-UNIX-Bypassing Golden Host-Direct Root Connection Attempt", "fileType": "Rule", "ruleThreadId": "NQVtdFOOABDrKsmLWpyq8g==", "cs2": "<Resource URI=\"\"\/All Rules\/Real-time Rules\/FOO-ACCESS CONTROL and AUTHORIZATION\/FOO\/Unix Server\/FOO-UNIX-Bypassing Golden Host-Direct Root Connection Attempt\"\" ID=\"\"5lzFOO--RTSN-TESTQ==\"\"\/>", "flexString2": "DC0001-988", "locality": "1", "cs2Label": "Configuration Resource", "ahost": "foo.bar", "agt": "10.0.0.1", "av": "10.0.0.12", "atz": "Europe\/Berlin", "aid": "34rSQWFOOOBCAVlswcKFkbA==", "at": "superagent_ng", "dvchost": "server.foo.bar", "dvc": "10.0.0.1", "deviceZoneID": "Mbb8pFOOODol1dBKdURJA==", "deviceZoneURI": "\/All Zones\/FOO Solutions\/Prod\/GERMANY\/FOO US2 Class6 A 508 10.0.0.1-10.0.0.1", "dtz": "Europe\/Berlin", "deviceFacility": "Rules Engine", "eventAnnotationStageUpdateTime": "1427882444192", "eventAnnotationModificationTime": "1427882444192", "eventAnnotationAuditTrail": "1,1427453188050,root,Queued,,,,\n", "eventAnnotationVersion": "1", "eventAnnotationFlags": "0", "eventAnnotationEndTime": "1427881661000", "eventAnnotationManagerReceiptTime": "1427882444085", "_cefVer": "0.1", "ad.arcSightEventPath": "3VcygrkkBABCAYFOOLlU13A==", "baseEventIds": "24934003731\"" } } }'


cleanup_tmp_files

