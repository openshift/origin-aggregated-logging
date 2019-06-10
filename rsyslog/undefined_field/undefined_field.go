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
	"encoding/json"
	"bufio"
	"strconv"
	"strings"
	"fmt"
	"os"
)

const (
	initial_undefined_debug            = false
	initial_merge_json_log             = false
	initial_use_undefined              = false
	initial_undefined_name             = "undefined"
	initial_undefined_to_string        = false
	initial_default_keep_fields        = "CEE,time,@timestamp,aushape,ci_job,collectd,docker,fedora-ci,file,foreman,geoip,hostname,ipaddr4,ipaddr6,kubernetes,level,message,namespace_name,namespace_uuid,offset,openstack,ovirt,pid,pipeline_metadata,rsyslog,service,systemd,tags,testcase,tlog,viaq_msg_id"
	initial_extra_keep_fields          = ""
	initial_keep_empty_fields          = ""
	initial_undefined_max_num_fields   = -1
	initial_undefined_dot_replace_char = "UNUSED"
	initial_logging_file_path          = "/var/log/rsyslog/rsyslog.log"
	undefined_config                   = "/var/lib/rsyslog.pod/undefined.json"
	noChanges                          = "{}"
)

var (
	undefined_debug bool
	merge_json_log bool
	use_undefined bool
	keep_fields map[string]string
	keep_empty_fields map[string]string
	undefined_name string
	undefined_to_string bool
	undefined_dot_replace_char string
	undefined_max_num_fields int64
	logfile *os.File
	noaction		  = false
	replacer		  = &strings.Replacer{}
)

func getMapStringValue(m map[string]interface{}, key string) (string, bool) {
	if val, ok := m[key]; ok {
		return val.(string), ok
	} else {
		return "", ok
	}
}

func onInit() {
	// opening the rsyslog log file
	logging_file_path := initial_logging_file_path
	if eval := os.Getenv("LOGGING_FILE_PATH"); eval != "" {
		logging_file_path = eval
	}
	if f, err := os.OpenFile(logging_file_path, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644); err == nil {
		logfile = f
	} else {
		panic(fmt.Errorf("Could not open file [%s]: [%v]", logging_file_path, err))
	}

	// initializing
	undefined_debug = initial_undefined_debug
	merge_json_log = initial_merge_json_log
	use_undefined = initial_use_undefined
	default_keep_fields := initial_default_keep_fields
	extra_keep_fields := initial_extra_keep_fields
	undefined_name = initial_undefined_name
	tmp_keep_empty_fields := initial_keep_empty_fields
	undefined_to_string = initial_undefined_to_string
	undefined_dot_replace_char = initial_undefined_dot_replace_char
	undefined_max_num_fields = initial_undefined_max_num_fields

	if config, err := os.Open(undefined_config); err == nil {
		reader := bufio.NewReader(config)
		scanner := bufio.NewScanner(reader)
		scanner.Split(bufio.ScanLines)
		for scanner.Scan() {
			rawStr := scanner.Text()
			// skip comments
			if strings.HasPrefix(rawStr, "#") {
				continue
			}
			configMap := make(map[string]interface{})
			if err := json.Unmarshal([]byte(rawStr), &configMap); err != nil {
				fmt.Fprintln(logfile, "ERROR: Failed to parse config file [%s]: [%v]", undefined_config, err)
				panic(fmt.Errorf("Failed to parse config file [%s]: [%v]", undefined_config, err))
			}

			if val, ok := getMapStringValue(configMap, "UNDEFINED_DEBUG"); ok {
				if rval, err := strconv.ParseBool(val); err == nil {
					undefined_debug = rval
				} else {
					fmt.Fprintln(logfile, "ERROR: Invalid UNDEFINED_DEBUG value [%s]: [%v]", val, err)
					panic(fmt.Errorf("Invalid UNDEFINED_DEBUG value [%s]: [%v]", val, err))
				}
			}
			if val, ok := getMapStringValue(configMap, "MERGE_JSON_LOG"); ok {
				if rval, err := strconv.ParseBool(val); err == nil {
					merge_json_log = rval
				} else {
					fmt.Fprintln(logfile, "ERROR: Invalid MERGE_JSON_LOG value [%s]: [%v]", val, err)
					panic(fmt.Errorf("Invalid MERGE_JSON_LOG value [%s]: [%v]", val, err))
				}
			}
			if val, ok := getMapStringValue(configMap, "CDM_USE_UNDEFINED"); ok {
				if rval, err := strconv.ParseBool(val); err == nil {
					use_undefined = rval
				} else {
					fmt.Fprintln(logfile, "ERROR: Invalid CDM_USE_UNDEFINED value [%s]: [%v]", val, err)
					panic(fmt.Errorf("Invalid CDM_USE_UNDEFINED value [%s]: [%v]", val, err))
				}
			}
			if val, ok := getMapStringValue(configMap, "CDM_DEFAULT_KEEP_FIELDS"); ok {
				default_keep_fields = val
			}
			if val, ok := getMapStringValue(configMap, "CDM_EXTRA_KEEP_FIELDS"); ok {
				extra_keep_fields = val
			}
			if val, ok := getMapStringValue(configMap, "CDM_UNDEFINED_NAME"); ok {
				undefined_name = val
			}
			if val, ok := getMapStringValue(configMap, "CDM_KEEP_EMPTY_FIELDS"); ok {
				tmp_keep_empty_fields = val
			}
			if val, ok := getMapStringValue(configMap, "CDM_UNDEFINED_TO_STRING"); ok {
				if rval, err := strconv.ParseBool(val); err == nil {
					undefined_to_string = rval
				} else {
					fmt.Fprintln(logfile, "ERROR: Invalid CDM_UNDEFINED_TO_STRING value [%s]: [%v]", val, err)
					panic(fmt.Errorf("Invalid CDM_UNDEFINED_TO_STRING value [%s]: [%v]", val, err))
				}
			}
			if val, ok := getMapStringValue(configMap, "CDM_UNDEFINED_DOT_REPLACE_CHAR"); ok {
				undefined_dot_replace_char = val
			}
			if val, ok := getMapStringValue(configMap, "CDM_UNDEFINED_MAX_NUM_FIELDS"); ok {
				var rval64 int64
				if rval64, err = strconv.ParseInt(val, 10, 64); err == nil {
					undefined_max_num_fields = rval64
				} else {
					fmt.Fprintln(logfile, "ERROR: Invalid CDM_UNDEFINED_MAX_NUM_FIELDS value [%s]: [%v]", val, err)
					panic(fmt.Errorf("Invalid CDM_UNDEFINED_MAX_NUM_FIELDS value [%s]: [%v]", val, err))
				}
			}
		}
		defer config.Close()
	} else if !strings.Contains(err.Error(), "no such file or directory") {
		fmt.Fprintln(logfile, "ERROR: Could not open config file [%s]: [%v]", undefined_config, err)
		panic(fmt.Errorf("Could not open config file [%s]: [%v]", undefined_config, err))
	}

	if !use_undefined && tmp_keep_empty_fields == "" && !undefined_to_string && undefined_dot_replace_char == "UNUSED" {
		noaction = true
	}
	if undefined_max_num_fields == -1 {
		undefined_max_num_fields = int64(^uint(0) >> 1)
	}
	if use_undefined {
		tmp_default := strings.Split(default_keep_fields, ",")
		tmp_extra := strings.Split(extra_keep_fields, ",")
		keep_fields = make(map[string]string)
		for _, str := range tmp_default {
			keep_fields[str] = str
		}
		for _, str := range tmp_extra {
			keep_fields[str] = str
		}
	}
	tmp := strings.Split(tmp_keep_empty_fields, ",")
	keep_empty_fields = make(map[string]string)
	for _, str := range tmp {
		keep_empty_fields[str] = str
	}

	if undefined_dot_replace_char != "UNUSED" {
		replacer = strings.NewReplacer(".", undefined_dot_replace_char)
	}

	fmt.Fprintln(logfile, "mmexternal: merge_json_log: ", merge_json_log)
	fmt.Fprintln(logfile, "mmexternal: use_undefined: ", use_undefined)
	fmt.Fprintln(logfile, "mmexternal: default_keep_fields: ", default_keep_fields)
	fmt.Fprintln(logfile, "mmexternal: extra_keep_fields: ", extra_keep_fields)
	fmt.Fprintln(logfile, "mmexternal: undefined_name: ", undefined_name)
	fmt.Fprintln(logfile, "mmexternal: keep_empty_fields: ", tmp_keep_empty_fields)
	fmt.Fprintln(logfile, "mmexternal: undefined_to_string: ", undefined_to_string)
	fmt.Fprintln(logfile, "mmexternal: undefined_dot_replace_char: ", undefined_dot_replace_char)
	fmt.Fprintln(logfile, "mmexternal: undefined_max_num_fields: ", undefined_max_num_fields)
	fmt.Fprintln(logfile, "mmexternal: noaction: ", noaction)
}

func replaceDotMoveUndefined(jsonMap map[string]interface{}, topPropLevel bool) (map[string]interface{},bool,bool) {
	replace_me := false
	has_undefined := false
	cp := make(map[string]interface{})
	for origkey, value := range jsonMap {
		key := origkey
		if topPropLevel && merge_json_log && undefined_dot_replace_char != "UNUSED" {
			// replace '.' with specified char (e.g., '_')
			key = replacer.Replace(origkey)
			if key != origkey {
				replace_me = true
			}
		}
		// skip empty or not?
		valuemap, ismap := value.(map[string]interface{})
		valuearraymap, isarraymap := value.([]map[string]interface{})
		if _, exists := keep_empty_fields[origkey]; !exists {
			if !ismap && (value == nil || len(value.(string)) == 0) ||
				isarraymap && len(valuearraymap) == 0 ||
				ismap && len(valuemap) == 0 {
				replace_me = true
				continue
			}
		}
		// use_undefined and key is not in keep_fields?
		_, keepit := keep_fields[origkey]
		if topPropLevel && use_undefined && !keepit {
			// if unmdefined_max_num_fields > 0, move the undefined item to undefined_name
			if undefined_max_num_fields > 0 {
				if cp[undefined_name] == nil {
					subcp := make(map[string]interface{})
					cp[undefined_name] = subcp
				}
				if ismap {
					rval, _, _ := replaceDotMoveUndefined(valuemap, false)
					if len(rval) > 0 {
						cp[undefined_name].(map[string]interface{})[key] = rval
					}
				} else {
					cp[undefined_name].(map[string]interface{})[key] = value
				}
				undefined_max_num_fields--
				replace_me = true
				has_undefined = true
			}
		} else if ismap {
			rval, _, _ := replaceDotMoveUndefined(valuemap, false)
			cp[key] = rval
		} else {
			cp[key] = value
		}
	}
	return cp, replace_me, has_undefined
}

func main() {

	onInit()
	defer logfile.Close()

	reader := bufio.NewReader(os.Stdin)
	scanner := bufio.NewScanner(reader)
	scanner.Split(bufio.ScanLines)

	for scanner.Scan() {
		jsonCopyMap := make(map[string]interface{})
		jsonMap := make(map[string]interface{})
		rawStr := scanner.Text()
		if noaction {
			fmt.Fprintln(logfile, "No Action Needed: ", rawStr, "(", string(noChanges), ")")
			fmt.Println(noChanges)
			continue
		}
		if undefined_debug {
			fmt.Fprintln(logfile, "Source: ", rawStr)
		}
		if err := json.Unmarshal([]byte(rawStr), &jsonMap); err != nil {
			fmt.Fprintln(logfile, "json.Unmarshal failed (", err, "): ", rawStr)
			fmt.Println(noChanges)
			continue
		}
		if jsonMap["$!"] == nil {
			continue
		}
		topval, ismap := jsonMap["$!"].(map[string]interface{})
		if !ismap {
			fmt.Fprintln(logfile, "Result is String: ", rawStr, "(", string(noChanges), ")")
			fmt.Println(noChanges)
			continue
		}
		if jsonCopyMap["$!"] == nil {
			jsonCopyMap["$!"] = make(map[string]interface{})
		}
		all, replace_me, has_undefined := replaceDotMoveUndefined(topval, true)
		if !replace_me {
			fmt.Fprintln(logfile, "No Need to Replace: ", rawStr, "(", string(noChanges), ")")
			fmt.Println(noChanges)
			continue
		}
		jsonCopyMap["$!"].(map[string]interface{})["openshift_logging_all"] = all
		if tmp_val, err := json.Marshal(jsonCopyMap); err == nil {
			if use_undefined && undefined_to_string && has_undefined {
				if err := json.Unmarshal([]byte(tmp_val), &jsonCopyMap); err == nil {
					// if unmarshal fails, giving up converting to string...
					if undefined, err := json.Marshal(jsonCopyMap[undefined_name]); err == nil {
						jsonCopyMap[undefined_name] = string(undefined)
						if tmp_val0, err := json.Marshal(jsonCopyMap); err == nil {
							tmp_val = tmp_val0
						} else {
							fmt.Fprintln(logfile, "Marshaling undefined value converted to string failed (", err, "): ", tmp_val)
						}
					} else {
						fmt.Fprintln(logfile, "Marshaling undefined value failed (", err, "): ", tmp_val)
					}
				} else {
					fmt.Fprintln(logfile, "Parsing processed json failed (", err, "): ", tmp_val)
				}
			}
			if undefined_debug {
				fmt.Fprintln(logfile, "Result: ", string(tmp_val))
			}
			fmt.Println(string(tmp_val))
		} else {
			fmt.Fprintln(logfile, "Final Marshal failed (", err, "): ", rawStr)
			fmt.Println(noChanges)
		}
	}
}
