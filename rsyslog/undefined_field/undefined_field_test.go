package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
	"reflect"
	"testing"
)

var (
	testLogfile *os.File
)

func setup(t *testing.T, cfg undefinedConfig) error {
	var err error
	testLogfile, err = ioutil.TempFile("", "log")
	if err != nil {
		return fmt.Errorf("Could not create temp log file: %v", err)
	}
	testCfgfile, err := ioutil.TempFile("", "cfg")
	if err != nil {
		os.Remove(testLogfile.Name())
		return fmt.Errorf("Could not create temp cfg file")
	}
	defer os.Remove(testCfgfile.Name())
	os.Setenv("LOGGING_FILE_PATH", testLogfile.Name())
	// write cfg options to testCfgfile
	b, err := json.Marshal(cfg)
	if err != nil {
		os.Remove(testLogfile.Name())
		return fmt.Errorf("Could not marshal JSON config object: %v", err)
	}
	if _, err := testCfgfile.Write(b); err != nil {
		os.Remove(testLogfile.Name())
		return fmt.Errorf("Could not write config to %v: %v", testCfgfile.Name(), err)
	}
	os.Setenv("UNDEFINED_CONFIG", testCfgfile.Name())
	testLogfile.Close()
	onInit()
	return nil
}

func teardown(t *testing.T) {
	tdLogfile, err := os.Open(testLogfile.Name())
	if err != nil {
		t.Errorf("Could not open testLogfile: %v", err)
		return
	}
	fi, err := tdLogfile.Stat()
	if err != nil {
		tdLogfile.Close()
		t.Errorf("Could not seek to end of testLogfile: %v", err)
		return
	}
	_, err = tdLogfile.Seek(0, 0)
	if err != nil {
		tdLogfile.Close()
		t.Errorf("Could not rewind testLogfile: %v", err)
		return
	}
	buf := make([]byte, fi.Size())
	_, err = tdLogfile.Read(buf)
	if err != nil {
		tdLogfile.Close()
		t.Errorf("Could not read %v bytes from testLogfile: %v", fi.Size(), err)
		return
	}
	tdLogfile.Close()
	t.Logf("Test output: %s", buf)
	os.Remove(testLogfile.Name())
}

func checkFieldsEqual(t *testing.T, expected, actual map[string]interface{}, fieldlist []string) error {
	var err error
	for _, field := range fieldlist {
		if !reflect.DeepEqual(expected[field], actual[field]) {
			t.Errorf("field [%s] expected value [%v] does not match actual value [%v]",
				field, expected[field], actual[field])
			if err == nil {
				err = fmt.Errorf("one or more field values did not match")
			}
		}
	}
	return err
}

func checkFieldsNotIncluded(t *testing.T, actual map[string]interface{}, fieldlist []string) error {
	var err error
	for _, field := range fieldlist {
		if actual[field] != nil {
			t.Errorf("field [%s] is found in the actual map", field)
			err = fmt.Errorf("one or more unexpected fields are included")
		}
	}
	return err
}

func TestKeepEmpty(t *testing.T) {
	testcfg := undefinedConfig{
		Debug:                   true,
		MergeJSONLog:            true,
		UseUndefined:            true,
		UndefinedToString:       false,
		DefaultKeepFields:       "method,statusCode,type,@timestamp,req,res,CONTAINER_NAME,CONTAINER_ID_FULL",
		ExtraKeepFields:         "undefined4,undefined5,empty1,undefined3",
		UndefinedName:           "undefined",
		KeepEmptyFields:         "undefined4,undefined5,empty1,undefined3",
		UndefinedDotReplaceChar: "UNUSED",
		UndefinedMaxNumFields:   -1,
	}
	err := setup(t, testcfg)
	defer teardown(t)
	if err != nil {
		t.Errorf("test setup failed: %v", err)
	}
	inputString := `{"@timestamp": "2019-07-17T21:26:45.913217+00:00", ` +
		`"undefined1": "undefined1", "undefined11": 1111, "undefined12": true, "empty1": "", ` +
		`"undefined2": { "undefined2": "undefined2", "": "", "undefined22": 2222, "undefined23": false }, ` +
		`"undefined3": { "emptyvalue": "" }, "undefined4": {}, "undefined5": "undefined5", ` +
		`"undefined.6": "undefined6" }`
	inputMap := make(map[string]interface{})
	if err := json.Unmarshal([]byte(inputString), &inputMap); err != nil {
		t.Errorf("json.Unmarshal failed for inputString [%v]: %v", inputString, err)
	}
	origMap := make(map[string]interface{})
	if err := json.Unmarshal([]byte(inputString), &origMap); err != nil {
		t.Errorf("json.Unmarshal failed for inputString [%v]: %v", inputString, err)
	}
	changed := processUndefinedAndEmpty(inputMap, true, true)
	if !changed {
		t.Errorf("Expected changes not performed on the input")
	}
	outputBytes, _ := json.Marshal(inputMap)
	t.Logf("outputBytes [%s]", outputBytes)
	fieldlist := []string{"@timestamp", "empty1", "undefined3", "undefined4", "undefined5"}
	if err = checkFieldsEqual(t, origMap, inputMap, fieldlist); err != nil {
		t.Error(err)
	}
	var val1 float64 = 1111
	var val2 float64 = 2222
	undefined2Map := map[string]interface{}{
		"undefined2":  "undefined2",
		"undefined22": val2,
		"undefined23": false,
	}
	undefinedMap := map[string]interface{}{
		"undefined1":  "undefined1",
		"undefined11": val1,
		"undefined12": true,
		"undefined2":  undefined2Map,
		"undefined.6": "undefined6",
	}
	fieldlist = []string{"undefined1", "undefined11", "undefined12", "undefined2", "undefined.6"}
	if err = checkFieldsEqual(t, undefinedMap, inputMap, fieldlist); err != nil {
		t.Error(err)
	}
}

func TestUndefinedMaxNumFields(t *testing.T) {
	cfg = undefinedConfig{
		Debug:                   true,
		MergeJSONLog:            true,
		UseUndefined:            true,
		UndefinedToString:       false,
		DefaultKeepFields:       "method,statusCode,type,@timestamp,req,res,CONTAINER_NAME,CONTAINER_ID_FULL",
		ExtraKeepFields:         "undefined4,undefined5,empty1,undefined3",
		UndefinedName:           "undefined",
		KeepEmptyFields:         "undefined4,undefined5,empty1,undefined3",
		UndefinedDotReplaceChar: "UNUSED",
		// the test should have 5 undefined fields - if UndefinedMaxNumFields == number of undefined fields - 1
		// this allows us to check for off-by-one errors as well
		UndefinedMaxNumFields: 4,
	}
	err := setup(t, cfg)
	defer teardown(t)
	if err != nil {
		t.Errorf("test setup failed: %v", err)
	}
	inputString := `{"@timestamp": "2019-07-17T21:26:45.913217+00:00", ` +
		`"undefined1": "undefined1", "undefined11": 1111, "undefined12": true, "empty1": "", ` +
		`"undefined2": { "undefined2": "undefined2", "": "", "undefined22": 2222, "undefined23": false }, ` +
		`"undefined3": { "emptyvalue": "" }, "undefined4": {}, "undefined5": "undefined5", ` +
		`"undefined.6": "undefined6" }`
	inputMap := make(map[string]interface{})
	if err := json.Unmarshal([]byte(inputString), &inputMap); err != nil {
		t.Errorf("json.Unmarshal failed for inputString [%v]: %v", inputString, err)
	}
	origMap := make(map[string]interface{})
	if err := json.Unmarshal([]byte(inputString), &origMap); err != nil {
		t.Errorf("json.Unmarshal failed for inputString [%v]: %v", inputString, err)
	}
	expectedUndefString := `{"undefined.6":"undefined6","undefined1":"undefined1","undefined11":1111,"undefined12":true,"undefined2":{"":"","undefined2":"undefined2","undefined22":2222,"undefined23":false}}`
	undefString, undefMap, _ := processUndefinedAndMaxNumFields(inputMap)
	outputBytes, _ := json.Marshal(inputMap)
	t.Logf("outputBytes [%s] undefString [%s] undefMap [%v]", outputBytes, undefString, undefMap)
	if undefMap != nil {
		t.Errorf("undefMap should be nil but has value %v", undefMap)
	}
	fieldlist := []string{"@timestamp", "empty1", "undefined3", "undefined4", "undefined5"}
	if err = checkFieldsEqual(t, origMap, inputMap, fieldlist); err != nil {
		t.Error(err)
	}
	// convert undefString back to map for comparison purposes
	undefMap = make(map[string]interface{})
	if err = json.Unmarshal([]byte(undefString), &undefMap); err != nil {
		t.Errorf("Could not convert undefString [%s] back to map: %v", undefString, err)
	}
	expectedUndefMap := make(map[string]interface{})
	if err = json.Unmarshal([]byte(expectedUndefString), &expectedUndefMap); err != nil {
		t.Errorf("Could not convert expectedUndefString [%s] back to map: %v", expectedUndefString, err)
	}
	fieldlist = []string{"undefined1", "undefined11", "undefined12", "undefined2", "undefined.6"}
	if err = checkFieldsEqual(t, expectedUndefMap, undefMap, fieldlist); err != nil {
		t.Error(err)
	}
}

func TestUndefinedToString(t *testing.T) {
	testcfg := undefinedConfig{
		Debug:                   true,
		MergeJSONLog:            true,
		UseUndefined:            true,
		UndefinedToString:       true,
		DefaultKeepFields:       "method,statusCode,type,@timestamp,req,res,CONTAINER_NAME,CONTAINER_ID_FULL",
		ExtraKeepFields:         "undefined4,undefined5,empty1,undefined3",
		UndefinedName:           "undefined",
		KeepEmptyFields:         "undefined4,undefined5,empty1,undefined3",
		UndefinedDotReplaceChar: "UNUSED",
		UndefinedMaxNumFields:   -1,
	}
	err := setup(t, testcfg)
	defer teardown(t)
	if err != nil {
		t.Errorf("test setup failed: %v", err)
	}
	inputString := `{"@timestamp": "2019-07-17T21:26:45.913217+00:00", ` +
		`"undefined1": "undefined1", "undefined11": 1111, "undefined12": true, "empty1": "", ` +
		`"undefined2": { "undefined2": "undefined2", "": "", "undefined22": 2222, "undefined23": false }, ` +
		`"undefinedary": ["a",1,false,{"b":"c"},["d",2,true,{"e":"f"}]],` +
		`"undefined3": { "emptyvalue": "" }, "undefined4": {}, "undefined5": "undefined5", ` +
		`"undefined.6": "undefined6" }`
	expectedOutputString := `{"@timestamp": "2019-07-17T21:26:45.913217+00:00", ` +
		`"undefined1": "undefined1", "undefined11": "1111", "undefined12": "true", "empty1": "", ` +
		`"undefined2": "{ \"undefined2\": \"undefined2\", \"\": \"\", \"undefined22\": 2222, \"undefined23\": false }", ` +
		`"undefinedary": "[\"a\",1,false,{\"b\":\"c\"},[\"d\",2,true,{\"e\":\"f\"}]]",` +
		`"undefined3": { "emptyvalue": "" }, "undefined4": {}, "undefined5": "undefined5", ` +
		`"undefined.6": "undefined6" }`
	inputMap := make(map[string]interface{})
	if err := json.Unmarshal([]byte(inputString), &inputMap); err != nil {
		t.Errorf("json.Unmarshal failed for inputString [%v]: %v", inputString, err)
	}
	origMap := make(map[string]interface{})
	if err := json.Unmarshal([]byte(inputString), &origMap); err != nil {
		t.Errorf("json.Unmarshal failed for inputString [%v]: %v", inputString, err)
	}
	changed := processUndefinedAndEmpty(inputMap, true, true)
	if !changed {
		t.Errorf("Expected changes not performed on the input")
	}
	outputBytes, _ := json.Marshal(inputMap)
	t.Logf("outputBytes [%s]", outputBytes)
	expectedOutputMap := make(map[string]interface{})
	if err = json.Unmarshal([]byte(expectedOutputString), &expectedOutputMap); err != nil {
		t.Errorf("Could not convert expectedOutputString [%s] to map: %v", expectedOutputString, err)
	}
	t.Logf("using s [%s] using v [%v]", expectedOutputMap, expectedOutputMap)
	expectedUndef2 := expectedOutputMap["undefined2"]
	delete(expectedOutputMap, "undefined2")
	expectedUndefAryStr := expectedOutputMap["undefinedary"]
	delete(expectedOutputMap, "undefinedary")
	actualUndef2 := inputMap["undefined2"]
	delete(inputMap, "undefined2")
	actualUndefAryStr := inputMap["undefinedary"]
	delete(inputMap, "undefinedary")
	t.Logf("expected undef2 [%s] undefary [%s] actual undef2 [%s] undefary [%s]", expectedUndef2, expectedUndefAryStr, actualUndef2, actualUndefAryStr)

	if !reflect.DeepEqual(expectedOutputMap, inputMap) {
		t.Errorf("expected [%s] does not match actual [%s]", expectedOutputString, outputBytes)
	}

	expectedUndef2Map := make(map[string]interface{})
	if err = json.Unmarshal([]byte(expectedUndef2.(string)), &expectedUndef2Map); err != nil {
		t.Errorf("Could not convert expectedUndef2 [%s] to map: %v", expectedUndef2, err)
	}
	actualUndef2Map := make(map[string]interface{})
	if err = json.Unmarshal([]byte(actualUndef2.(string)), &actualUndef2Map); err != nil {
		t.Errorf("Could not convert actualUndef2 [%s] to map: %v", actualUndef2, err)
	}
	if !reflect.DeepEqual(expectedUndef2Map, actualUndef2Map) {
		t.Errorf("field undefined2 expected [%s] does not match actual [%s]", expectedUndef2, actualUndef2)
	}

	var expectedUndefAry []interface{}
	if err = json.Unmarshal([]byte(expectedUndefAryStr.(string)), &expectedUndefAry); err != nil {
		t.Errorf("Could not convert expectedUndefAryStr [%s] to array: %v", expectedUndefAryStr, err)
	}
	var actualUndefAry []interface{}
	if err = json.Unmarshal([]byte(actualUndefAryStr.(string)), &actualUndefAry); err != nil {
		t.Errorf("Could not convert actualUndefAryStr [%s] to array: %v", actualUndefAryStr, err)
	}
	if !reflect.DeepEqual(expectedUndefAry, actualUndefAry) {
		t.Errorf("field undefinedary expected [%s] does not match actual [%s]", expectedUndefAryStr, actualUndefAryStr)
	}

}

func TestUseUndefined(t *testing.T) {
	testcfg := undefinedConfig{
		Debug:                   true,
		MergeJSONLog:            false,
		UseUndefined:            true,
		UndefinedToString:       false,
		DefaultKeepFields:       "method,statusCode,type,@timestamp,req,res,CONTAINER_NAME,CONTAINER_ID_FULL",
		ExtraKeepFields:         "",
		UndefinedName:           "undefined",
		KeepEmptyFields:         "",
		UndefinedDotReplaceChar: "UNUSED",
		UndefinedMaxNumFields:   -1,
	}
	err := setup(t, testcfg)
	defer teardown(t)
	if err != nil {
		t.Errorf("test setup failed: %v", err)
	}
	inputString := `{"@timestamp": "2019-07-17T21:26:45.913217+00:00", ` +
		`"undefined1": "undefined1", "undefined11": 1111, "undefined12": true, "empty1": "", ` +
		`"undefined2": { "undefined2": "undefined2", "": "", "undefined22": 2222, "undefined23": false }, ` +
		`"undefined3": { "emptyvalue": "" }, "undefined4": {}, "undefined5": "undefined5", ` +
		`"undefined.6": "undefined6" }`
	inputMap := make(map[string]interface{})
	if err := json.Unmarshal([]byte(inputString), &inputMap); err != nil {
		t.Errorf("json.Unmarshal failed for inputString [%v]: %v", inputString, err)
	}
	origMap := make(map[string]interface{})
	if err := json.Unmarshal([]byte(inputString), &origMap); err != nil {
		t.Errorf("json.Unmarshal failed for inputString [%v]: %v", inputString, err)
	}
	changed := processUndefinedAndEmpty(inputMap, true, true)
	if !changed {
		t.Errorf("Expected changes not performed on the input")
	}
	outputBytes, _ := json.Marshal(inputMap)
	t.Logf("outputBytes [%s]", outputBytes)
	fieldlist := []string{"@timestamp"}
	if err = checkFieldsEqual(t, origMap, inputMap, fieldlist); err != nil {
		t.Error(err)
	}
	var val1 float64 = 1111
	var val2 float64 = 2222
	undefined2Map := map[string]interface{}{
		"undefined2":  "undefined2",
		"undefined22": val2,
		"undefined23": false,
	}
	undefinedMap := map[string]interface{}{
		"undefined1":  "undefined1",
		"undefined11": val1,
		"undefined12": true,
		"undefined2":  undefined2Map,
		"undefined5":  "undefined5",
		"undefined.6": "undefined6",
	}
	fieldlist = []string{"undefined1", "undefined11", "undefined12", "undefined2", "undefined5", "undefined.6"}
	if err = checkFieldsEqual(t, undefinedMap, inputMap, fieldlist); err != nil {
		t.Error(err)
	}
}

func TestUseUndefined2(t *testing.T) {
	testcfg := undefinedConfig{
		Debug:                   true,
		MergeJSONLog:            false,
		UseUndefined:            true,
		UndefinedToString:       false,
		DefaultKeepFields:       "method,statusCode,type,@timestamp,req,res,CONTAINER_NAME,CONTAINER_ID_FULL",
		ExtraKeepFields:         "",
		UndefinedName:           "undefined",
		KeepEmptyFields:         "",
		UndefinedDotReplaceChar: "UNUSED",
		UndefinedMaxNumFields:   -1,
	}
	err := setup(t, testcfg)
	defer teardown(t)
	if err != nil {
		t.Errorf("test setup failed: %v", err)
	}
	inputString := `{"@timestamp": "2019-07-17T21:26:45.913217+00:00", ` +
		`"undefined1": "undefined1", "undefined11": 1111, "undefined12": true, "empty1": "", ` +
		`"undefined2": { "undefined2": "undefined2", "": "", "undefined22": 2222, "undefined23": false }, ` +
		`"undefined3": { "emptyvalue": "" }, "undefined4": {}, "undefined5": "undefined5", ` +
		`"undefined.6": "undefined6" }`
	inputMap := make(map[string]interface{})
	if err := json.Unmarshal([]byte(inputString), &inputMap); err != nil {
		t.Errorf("json.Unmarshal failed for inputString [%v]: %v", inputString, err)
	}
	origMap := make(map[string]interface{})
	if err := json.Unmarshal([]byte(inputString), &origMap); err != nil {
		t.Errorf("json.Unmarshal failed for inputString [%v]: %v", inputString, err)
	}
	expectedUndefString := `{"empty1":"","undefined.6":"undefined6","undefined1":"undefined1","undefined11":1111,"undefined12":true,"undefined2":{"":"","undefined2":"undefined2","undefined22":2222,"undefined23":false},"undefined3":{"emptyvalue":""},"undefined4":{},"undefined5":"undefined5"}`
	undefString, undefMap, _ := processUndefinedAndMaxNumFields(inputMap)
	outputBytes, _ := json.Marshal(inputMap)
	t.Logf("outputBytes [%s] undefString [%s] undefMap [%v]", outputBytes, undefString, undefMap)
	fieldlist := []string{"@timestamp"}
	if err = checkFieldsEqual(t, origMap, inputMap, fieldlist); err != nil {
		t.Error(err)
	}
	expectedUndefMap := make(map[string]interface{})
	if err = json.Unmarshal([]byte(expectedUndefString), &expectedUndefMap); err != nil {
		t.Errorf("Could not convert expectedUndefString [%s] back to map: %v", expectedUndefString, err)
	}
	fieldlist = []string{"undefined1", "undefined11", "undefined12", "undefined2", "undefined3", "undefined4", "undefined5", "undefined.6", "empty1"}
	if err = checkFieldsEqual(t, expectedUndefMap, undefMap, fieldlist); err != nil {
		t.Error(err)
	}
}

func TestUndefinedDotReplaceChar(t *testing.T) {
	testcfg := undefinedConfig{
		Debug:                   true,
		MergeJSONLog:            true,
		UseUndefined:            true,
		UndefinedToString:       false,
		DefaultKeepFields:       "method,statusCode,type,@timestamp,req,res,CONTAINER_NAME,CONTAINER_ID_FULL",
		ExtraKeepFields:         "undefined4,undefined5,empty1,undefined3",
		UndefinedName:           "undefined",
		KeepEmptyFields:         "undefined4,undefined5,empty1,undefined3",
		UndefinedDotReplaceChar: "@@@",
		UndefinedMaxNumFields:   -1,
	}
	err := setup(t, testcfg)
	defer teardown(t)
	if err != nil {
		t.Errorf("test setup failed: %v", err)
	}
	inputString := `{"@timestamp": "2019-07-17T21:26:45.913217+00:00", ` +
		`"undefined1": "undefined1", "undefined11": 1111, "undefined12": true, "empty1": "", ` +
		`"undefined2": { "undefined2": "undefined2", "": "", "undefined22": 2222, "undefined23": false }, ` +
		`"undefined3": { "emptyvalue": "" }, "undefined4": {}, "undefined5": "undefined5", ` +
		`"undefined.6": "undefined6" }`
	inputMap := make(map[string]interface{})
	if err := json.Unmarshal([]byte(inputString), &inputMap); err != nil {
		t.Errorf("json.Unmarshal failed for inputString [%v]: %v", inputString, err)
	}
	origMap := make(map[string]interface{})
	if err := json.Unmarshal([]byte(inputString), &origMap); err != nil {
		t.Errorf("json.Unmarshal failed for inputString [%v]: %v", inputString, err)
	}
	changed := processUndefinedAndEmpty(inputMap, true, true)
	if !changed {
		t.Errorf("Expected changes not performed on the input")
	}
	outputBytes, _ := json.Marshal(inputMap)
	t.Logf("outputBytes [%s]", outputBytes)
	fieldlist := []string{"@timestamp", "empty1", "undefined3", "undefined4", "undefined5"}
	if err = checkFieldsEqual(t, origMap, inputMap, fieldlist); err != nil {
		t.Error(err)
	}
	var val1 float64 = 1111
	var val2 float64 = 2222
	undefined2Map := map[string]interface{}{
		"undefined2":  "undefined2",
		"undefined22": val2,
		"undefined23": false,
	}
	undefinedMap := map[string]interface{}{
		"undefined1":  "undefined1",
		"undefined11": val1,
		"undefined12": true,
		"undefined2":  undefined2Map,
		"undefined@@@6": "undefined6",
	}
	fieldlist = []string{"undefined1", "undefined11", "undefined12", "undefined2", "undefined@@@6"}
	if err = checkFieldsEqual(t, undefinedMap, inputMap, fieldlist); err != nil {
		t.Error(err)
	}
}

func TestNestedEmptyFields(t *testing.T) {
	testcfg := undefinedConfig{
		Debug:                   true,
		MergeJSONLog:            true,
		UseUndefined:            true,
		UndefinedToString:       false,
		DefaultKeepFields:       "method,statusCode,type,@timestamp,req,res,CONTAINER_NAME,CONTAINER_ID_FULL",
		ExtraKeepFields:         "",
		UndefinedName:           "undefined",
		KeepEmptyFields:         "empty1,empty2,empty3,empty4",
		UndefinedDotReplaceChar: "UNUSED",
		UndefinedMaxNumFields:   -1,
	}
	err := setup(t, testcfg)
	defer teardown(t)
	if err != nil {
		t.Errorf("test setup failed: %v", err)
	}
	inputString := `{"@timestamp": "2019-07-17T21:26:45.913217+00:00", ` +
		`"undefined1": "", ` +
		`"empty1": "", ` +
		`"undefined2": { "emptyarray": { "ea0": "", "ea1": {} }, "": "", "nestedemptyarray": { "nea0": { "nea00": { "nea000": { "":"" }}}}}, ` +
		`"empty2": { "emptyarray": { "ea0": "", "ea1": {} }, "": "", "nestedemptyarray": { "nea0": { "nea00": { "nea000": { "":"" }}}}}, ` +
		`"undefined3": { "emptyvalue": "" }, ` +
		`"empty3": { "emptyvalue": "" }, ` +
		`"undefined4": {}, ` +
		`"empty4": {} }`
	inputMap := make(map[string]interface{})
	if err := json.Unmarshal([]byte(inputString), &inputMap); err != nil {
		t.Errorf("json.Unmarshal failed for inputString [%v]: %v", inputString, err)
	}
	origMap := make(map[string]interface{})
	if err := json.Unmarshal([]byte(inputString), &origMap); err != nil {
		t.Errorf("json.Unmarshal failed for inputString [%v]: %v", inputString, err)
	}
	changed := processUndefinedAndEmpty(inputMap, true, true)
	if !changed {
		t.Errorf("Expected changes not performed on the input")
	}
	outputBytes, _ := json.Marshal(inputMap)
	t.Logf("outputBytes [%s]", outputBytes)
	fieldlist := []string{"@timestamp", "empty1", "empty2", "empty3", "empty4"}
	if err = checkFieldsEqual(t, origMap, inputMap, fieldlist); err != nil {
		t.Error(err)
	}
	fieldlist = []string{"undefined1", "undefined2", "undefined3", "undefined4"}
	if err = checkFieldsNotIncluded(t, inputMap, fieldlist); err != nil {
		t.Error(err)
	}
}
