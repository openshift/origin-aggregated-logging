/**
 * undefined_field.go -- rsyslog plugin to process undefined fields and do some more treatments [1]
 *
 * Interface
 * Input  - mmexternal plugins receives $! property tree as well as local and global variables in the pipeline.
 * Output - only $! property tree can be returned to rsyslogd via standard output.
 *
 * Due to the spec of rsyslog, outputs from plugins are accumulated to the $! property tree.
 * To support move undefined fields in the tree and deleting empty fields, undefined_field
 * sets the processed property tree to $!openshift_logging_all and the result is supposed
 * to be reset to $! if needed.  See the following config example, where $! is cleaned up
 * before resetting the result from undefined_field.  If no changes are made in undefined_
 * field, it returns an empty json.  In that case, rsyslogd does not touch $!.
 *
 * How to use undefined_field
 * 1) compile - go build undefined_field.go
 * 2) rsyslog config example to call undefined_field
 *    module(load="mmexternal")
 *    action(type="mmexternal" binary="/usr/local/bin/undefined_field" interface.input="fulljson")
 *    if (strlen($!openshift_logging_all) > 0) then {
 *        set $.openshift_logging_all = $!openshift_logging_all;
 *          unset $!;
 *          set $! = $.openshift_logging_all;
 *          unset $.openshift_logging_all;
 *    }
 *
 * Parameters (Environment variables)
 *  CDM_USE_UNDEFINED
 *    - If set to "true", undefined fields are moved to the undefined property defined by CDM_UNDEFINED_NAME.
 *      default to "false".
 *  CDM_DEFAULT_KEEP_FIELDS
 *    - Default set of fields to be kept in the top level of json.
 *      default to "CEE,time,@timestamp,aushape,ci_job,collectd,docker,fedora-ci,file,foreman,geoip,hostname,ipaddr4,ipaddr6,kubernetes,level,message,namespace_name,namespace_uuid,offset,openstack,ovirt,pid,pipeline_metadata,rsyslog,service,systemd,tags,testcase,tlog,viaq_msg_id",
 *  CDM_EXTRA_KEEP_FIELDS -  "",
 *    - Extra set of fields to be kept in the top level of json.  A field not included in ${CDM_DEFAULT_KEEP_FIELDS}
 *      nor ${CDM_EXTRA_KEEP_FIELDS} are moved to ${CDM_UNDEFINED_NAME} if CDM_USE_UNDEFINED is "true".
 *      default to ""
 *  CDM_UNDEFINED_NAME
 *    - Undefined property name used when CDM_USE_UNDEFINED is set to "true".
 *      default to "undefined".
 *  CDM_KEEP_EMPTY_FIELDS
 *    - Empty fields are dropped except field names are set to CDM_KEEP_EMPTY_FIELDS in the CSV format.
 *      default to "".
 *  CDM_UNDEFINED_TO_STRING
 *    - If set to "true", when CDM_USE_UNDEFINED is "true" and undefined property with ${CDM_UNDEFINED_NAME} is created,
 *      the value is converted to the json string.  default to "false".
 *  CDM_UNDEFINED_DOT_REPLACE_CHAR (effective when MERGE_JSON_LOG is true)
 *    - a dot character '.' in a property name (key) is replaced with the specified character unless the value is not "UNUSED".
 *      default to "UNUSED".
 *  CDM_UNDEFINED_MAX_NUM_FIELDS -  "-1",
 *    - If a positive value is set, undefined fields are dropped once the number of fields has reached the value.
 *      default to "-1".
 *  UNDEFINED_DEBUG -  "false"
 *    - Debug flag used in undefined_field as well as the config file calling the plugin.
 *      default to "false".
 *
 * Note: the default values are defined in cluster-logging-operator/files/rsyslog/rsyslog.sh.
 *       The startup script generates the config file undefined.json explaned next.
 *
 * undefined_field expects a config file undefined.json in /var/lib/rsyslog.pod.
 * example undefined.json with default settings
 * {
 *    "CDM_USE_UNDEFINED": "false",
 *    "CDM_DEFAULT_KEEP_FIELDS": "CEE,time,@timestamp,aushape,ci_job,collectd,docker,fedora-ci,file,foreman,geoip,hostname,ipaddr4,ipaddr6,kubernetes,level,message,namespace_name,namespace_uuid,offset,openstack,ovirt,pid,pipeline_metadata,rsyslog,service,systemd,tags,testcase,tlog,viaq_msg_id",
 *    "CDM_EXTRA_KEEP_FIELDS": "",
 *    "CDM_UNDEFINED_NAME": "undefined",
 *    "CDM_KEEP_EMPTY_FIELDS": "",
 *    "CDM_UNDEFINED_TO_STRING": "false",
 *    "CDM_UNDEFINED_DOT_REPLACE_CHAR": "UNUSED",
 *    "CDM_UNDEFINED_MAX_NUM_FIELDS": "-1",
 *    "MERGE_JSON_LOG": "false",
 *    "UNDEFINED_DEBUG": "false"
 *  }
 */

package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
	"strings"
)

const (
	initialLoggingFilePath = "/var/log/rsyslog/rsyslog.log"
	defaultUndefinedConfig = "/var/lib/rsyslog.pod/undefined.json"
	noChanges              = "{}"
)

type undefinedConfig struct {
	Debug                   bool   `json:"UNDEFINED_DEBUG"`
	MergeJSONLog            bool   `json:"MERGE_JSON_LOG"`
	UseUndefined            bool   `json:"CDM_USE_UNDEFINED"`
	UndefinedToString       bool   `json:"CDM_UNDEFINED_TO_STRING"`
	DefaultKeepFields       string `json:"CDM_DEFAULT_KEEP_FIELDS"`
	ExtraKeepFields         string `json:"CDM_EXTRA_KEEP_FIELDS"`
	UndefinedName           string `json:"CDM_UNDEFINED_NAME"`
	KeepEmptyFields         string `json:"CDM_KEEP_EMPTY_FIELDS"`
	UndefinedDotReplaceChar string `json:"CDM_UNDEFINED_DOT_REPLACE_CHAR"`
	UndefinedMaxNumFields   int64  `json:"CDM_UNDEFINED_MAX_NUM_FIELDS"`
}

var (
	keepFields        map[string]string
	keepEmptyFields   map[string]string
	logfile           *os.File
	replacer          = &strings.Replacer{}
	checkMaxNumFields bool
	cfg               undefinedConfig
)

func onInit() {
	// opening the rsyslog log file
	loggingFilePath := initialLoggingFilePath
	if eval := os.Getenv("LOGGING_FILE_PATH"); eval != "" {
		loggingFilePath = eval
	}
	if f, err := os.OpenFile(loggingFilePath, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644); err == nil {
		logfile = f
	} else {
		panic(fmt.Errorf("Could not open file [%s]: [%v]", loggingFilePath, err))
	}

	undefinedConfigFile := defaultUndefinedConfig
	if eval := os.Getenv("UNDEFINED_CONFIG"); eval != "" {
		undefinedConfigFile = eval
	}
	if config, err := os.Open(undefinedConfigFile); err == nil {
		defer config.Close()
		configRead, _ := ioutil.ReadAll(config)
		json.Unmarshal(configRead, &cfg)
	} else if err != os.ErrNotExist {
		fmt.Fprintf(logfile, "ERROR: Could not open config file [%s]: [%v]\n", undefinedConfigFile, err)
		panic(fmt.Errorf("Could not open config file [%s]: [%v]", undefinedConfigFile, err))
	}

	if cfg.UndefinedMaxNumFields == -1 {
		checkMaxNumFields = false
		cfg.UndefinedMaxNumFields = int64(^uint(0) >> 1)
	} else {
		checkMaxNumFields = true
	}
	tmpDefault := strings.Split(cfg.DefaultKeepFields, ",")
	tmpExtra := strings.Split(cfg.ExtraKeepFields, ",")
	keepFields = make(map[string]string)
	for _, str := range tmpDefault {
		keepFields[str] = str
	}
	for _, str := range tmpExtra {
		keepFields[str] = str
	}
	tmp := strings.Split(cfg.KeepEmptyFields, ",")
	keepEmptyFields = make(map[string]string)
	for _, str := range tmp {
		keepEmptyFields[str] = str
	}

	if cfg.UndefinedDotReplaceChar != "UNUSED" {
		replacer = strings.NewReplacer(".", cfg.UndefinedDotReplaceChar)
	}

	if cfg.Debug {
		fmt.Fprintln(logfile, "mmexternal: merge_json_log: ", cfg.MergeJSONLog)
		fmt.Fprintln(logfile, "mmexternal: use_undefined: ", cfg.UseUndefined)
		fmt.Fprintln(logfile, "mmexternal: default_keep_fields: ", cfg.DefaultKeepFields)
		fmt.Fprintln(logfile, "mmexternal: extra_keep_fields: ", cfg.ExtraKeepFields)
		fmt.Fprintln(logfile, "mmexternal: undefined_name: ", cfg.UndefinedName)
		fmt.Fprintf(logfile, "mmexternal: keep_empty_fields: %v %v\n", cfg.KeepEmptyFields, keepEmptyFields)
		fmt.Fprintln(logfile, "mmexternal: undefined_to_string: ", cfg.UndefinedToString)
		fmt.Fprintln(logfile, "mmexternal: undefined_dot_replace_char: ", cfg.UndefinedDotReplaceChar)
		fmt.Fprintln(logfile, "mmexternal: undefinedMaxNumFields: ", cfg.UndefinedMaxNumFields)
	}
}

// This function has two purposes.
// 1) Check if the number of undefined fields exceeds the maximum value, if any.
//    If so, return a JSON string representation of a map of the undefined
//    fields, suitable for returning in the record[$undefined] value, and
//    the error, if any, returned from json.Marshal.
// 2) If use_undefined is true, move the undefined fields to a separate
//    map.
// Return values:
// * The JSON string representation of the map of the undefined fields if the
//   undefined field count exceeded the max, or ""
// * A map of the undefined fields if undefined field checking was enabled.
//   Otherwise, nil.  Map may be empty if there were no undefined fields.
// * err return from json.Marshal
// Side effects:
// The undefined fields are moved from the input map to the undefMap returned
func processUndefinedAndMaxNumFields(input map[string]interface{}) (string, map[string]interface{}, error) {
	if !checkMaxNumFields && !cfg.UseUndefined {
		return "", nil, nil // not used
	}
	count := cfg.UndefinedMaxNumFields
	var undefMap map[string]interface{}
	for field, val := range input {
		if _, keep := keepFields[field]; !keep {
			if undefMap == nil {
				undefMap = make(map[string]interface{})
			}
			undefMap[field] = val
			count--
		}
	}
	if undefMap == nil || len(undefMap) == 0 {
		return "", nil, nil // no undefined fields
	}
	if count < 0 || cfg.UseUndefined {
		for field := range undefMap {
			delete(input, field)
		}
		if checkMaxNumFields && count < 0 {
			// undefined fields converted to string - no undefMap
			b, err := json.Marshal(undefMap)
			return string(b), nil, err
		} else {
			// otherwise, returning undefMap - no undefString
			return "", undefMap, nil
		}
	}
	return "", nil, nil
}

func isFieldUndefined(field string, hasDefinedFields, hasUndefinedFields bool) bool {
	if !hasUndefinedFields {
		return false // input contains only defined fields
	} else if !hasDefinedFields {
		return true // input contains only undefined fields
	} else {
		_, definedField := keepFields[field] // see if field is a keeper
		return !definedField
	}
}

// convert the given field value to a string if not already a string
// modifies the value in input in place - if the returned bool is
// true, the field value was changed, and the new value is returned in the
// interface{} return value
func processUndefinedToString(input map[string]interface{}, field string, val interface{}) (interface{}, bool) {
	inputWasModified := false
	var newval string
	if _, isstring := val.(string); !isstring {
		bval, err := json.Marshal(val) // convert to JSON string
		if err == nil {
			newval = string(bval)
			input[field] = newval // replace val in-place
		} else {
			if cfg.Debug {
				fmt.Fprintf(logfile, "Could not convert field [%s] value [%v] to JSON string: %v\n", field, val, err)
			}
			// fallback
			newval = fmt.Sprintf("%v", val)
			input[field] = newval // replace val in-place
		}
		inputWasModified = true
	}
	return newval, inputWasModified
}

func processDotReplaceChar(field string, replacedFields map[string]string) (string, map[string]string) {
	newfield := replacer.Replace(field)
	if newfield != field {
		if replacedFields == nil {
			replacedFields = make(map[string]string)
		}
		replacedFields[field] = newfield
	}
	return newfield, replacedFields
}

// a value is empty if
// * it is nil
// * it is an empty string
// * it is a zero length array or map
// * it is an array and all its elements are empty
// * it is a map and all of its values are empty
func isEmpty(val interface{}) bool {
	switch tval := val.(type) {
	case nil:
		return true
	case string:
		return len(tval) == 0
	case []interface{}:
		return len(tval) == 0
	case map[string]interface{}:
		return len(tval) == 0
	default:
		return false // no other type can have an empty value
	}
}

// go through val recursively deleting any empty elements found
// returns the value with the empty elements removed
func delEmpty(val interface{}) (interface{}, bool) {
	changed := false
	elemChanged := false
	switch tval := val.(type) {
	case []interface{}:
		if len(tval) == 0 {
			return val, changed
		}
		result := tval[:0]
		for _, elem := range tval {
			elem, elemChanged = delEmpty(elem)
			if !isEmpty(elem) {
				result = append(result, elem)
			} else {
				changed = true
			}
			if elemChanged {
				changed = true
			}
		}
		return result, changed
	case map[string]interface{}:
		if len(tval) == 0 {
			return val, changed
		}
		for key, mapval := range tval {
			mapval, elemChanged = delEmpty(mapval)
			if isEmpty(mapval) {
				delete(tval, key)
				changed = true
			} else {
				tval[key] = mapval
			}
			if elemChanged {
				changed = true
			}
		}
		return val, changed
	default:
		return val, changed
	}
}

// process the undefined fields - convert to string value, convert
// "." in the field names to the undefined_dot_replace_char
// also remove empty fields
// The given input map may contain only undefined fields, or only
// defined fields, or a mix of both
// the given input map is modified in place
// Returns false if the input was unchanged
func processUndefinedAndEmpty(input map[string]interface{}, hasDefinedFields, hasUndefinedFields bool) bool {
	var replacedFields map[string]string // map old to new name
	inputWasModified := false
	for field, val := range input {
		newfield := field
		if isFieldUndefined(field, hasDefinedFields, hasUndefinedFields) {
			if cfg.UndefinedToString {
				newval, changed := processUndefinedToString(input, field, val)
				if changed {
					inputWasModified = true
					val = newval // use new val now
				}
			}
			if cfg.UndefinedDotReplaceChar != "UNUSED" && strings.Contains(field, ".") {
				newfield, replacedFields = processDotReplaceChar(field, replacedFields)
			}
		}
		// should be the newfield if using undefined_dot_replace_char
		_, keepEmpty := keepEmptyFields[newfield]
		if !keepEmpty {
			changed := false
			val, changed = delEmpty(val)
			if isEmpty(val) {
				inputWasModified = true
				delete(input, field)
			} else {
				input[field] = val
				if changed {
					inputWasModified = true
				}
			}
		}
	}
	if replacedFields != nil && len(replacedFields) > 0 {
		inputWasModified = true
		for oldfield, newfield := range replacedFields {
			input[newfield] = input[oldfield]
			delete(input, oldfield)
		}
	}
	return inputWasModified
}

// The given rawStr is only used for logging purposes.  The given
// input map is modified in-place.  The return value is false if there
// were errors, or no changes were made to the given input.  If the
// return value is true, the caller needs to handle outputting the
// new fields.
func processFields(rawStr string, input map[string]interface{}) bool {
	changes := false
	undefString, undefMap, err := processUndefinedAndMaxNumFields(input)
	if err != nil {
		// error marshalling undefined fields to JSON
		if cfg.Debug {
			fmt.Fprintf(logfile, "Unable to convert undefined fields to JSON string: %v : rawStr: %s\n", err, rawStr)
		}
		fmt.Println(noChanges)
		return changes
	}
	if len(undefString) > 0 || undefMap != nil {
		changes = true
	}
	if undefMap != nil {
		// changes is already true, so ignore the return value
		_ = processUndefinedAndEmpty(undefMap, false, true)
	}
	if len(input) > 0 {
		if processUndefinedAndEmpty(input, true, (undefMap == nil)) {
			changes = true
		}
	}
	if !changes {
		if cfg.Debug {
			fmt.Fprintln(logfile, "No Need to Replace for ", rawStr)
		}
		fmt.Println(noChanges)
		return changes
	}
	if len(undefString) > 0 {
		input[cfg.UndefinedName] = undefString
	} else if undefMap != nil && len(undefMap) > 0 {
		// if len is 0, means all fields were empty
		input[cfg.UndefinedName] = undefMap
	}
	return changes
}

func main() {

	onInit()
	defer logfile.Close()
	var reader *bufio.Reader
	var testInputFile *os.File
	if ff := os.Getenv("TEST_INPUT_FILE"); ff != "" {
		var err error
		testInputFile, err = os.Open(ff)
		if err != nil {
			panic(fmt.Errorf("Could not open %v: %v", ff, err))
		}
		reader = bufio.NewReader(testInputFile)
		defer testInputFile.Close()
	} else {
		reader = bufio.NewReader(os.Stdin)
	}
	scanner := bufio.NewScanner(reader)
	// Mitigating bufio.Scanner: token too long error
	const maxScanBufferSize = 256 * 1024
	scanBuffer := make([]byte, maxScanBufferSize)
	scanner.Buffer(scanBuffer, maxScanBufferSize)
	scanner.Split(bufio.ScanLines)

	for scanner.Scan() {
		jsonMap := make(map[string]interface{})
		rawStr := scanner.Text()
		if cfg.Debug {
			fmt.Fprintf(logfile, "Source (%d): %s\n", len(rawStr), rawStr)
		}
		if err := json.Unmarshal(scanner.Bytes(), &jsonMap); err != nil {
			fmt.Fprintln(logfile, "json.Unmarshal failed (", err, "): ", rawStr)
			fmt.Println(noChanges)
			continue
		}
		if jsonMap["$!"] == nil {
			fmt.Fprintln(logfile, "Source contains no $! field: ", rawStr)
			continue
		}
		topval, ismap := jsonMap["$!"].(map[string]interface{})
		if !ismap {
			if cfg.Debug {
				fmt.Fprintln(logfile, "Result is String: ", rawStr)
			}
			fmt.Println(noChanges)
			continue
		}
		if !processFields(rawStr, topval) {
			continue
		}
		loggingAll := map[string]interface{}{
			"openshift_logging_all": topval,
		}
		outputMap := map[string]interface{}{
			"$!": loggingAll,
		}
		outputString, err := json.Marshal(outputMap)
		if err != nil {
			if cfg.Debug {
				fmt.Fprintln(logfile, "Final Marshal failed (", err, "): ", rawStr)
			}
			fmt.Println(noChanges)
		} else {
			if cfg.Debug {
				fmt.Fprintln(logfile, "Result: ", string(outputString))
			}
			fmt.Println(string(outputString))
		}
	}

	if err := scanner.Err(); err != nil {
		fmt.Fprintf(logfile, "Scanner error [%v]\n", err)
	}
}
