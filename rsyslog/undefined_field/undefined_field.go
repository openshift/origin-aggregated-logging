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
	"encoding/json"
	"bufio"
	"strings"
	"fmt"
	"io/ioutil"
	"os"
)

const (
	initial_logging_file_path          = "/var/log/rsyslog/rsyslog.log"
	undefined_config                   = "/var/lib/rsyslog.pod/undefined.json"
	noChanges                          = "{}"
)

type UndefinedConfig struct {
  Debug bool `json:"UNDEFINED_DEBUG"`
  Merge_json_log bool `json:"MERGE_JSON_LOG"`
  Use_undefined bool `json:"CDM_USE_UNDEFINED"`
  Undefined_to_string bool `json:"CDM_UNDEFINED_TO_STRING"`
  Default_keep_fields string `json:"CDM_DEFAULT_KEEP_FIELDS"`
  Extra_keep_fields string `json:"CDM_EXTRA_KEEP_FIELDS"`
  Undefined_name string `json:"CDM_UNDEFINED_NAME"`
  Keep_empty_fields string `json:"CDM_KEEP_EMPTY_FIELDS"`
  Undefined_dot_replace_char string `json:"CDM_UNDEFINED_DOT_REPLACE_CHAR"`
  Undefined_max_num_fields int64 `json:"CDM_UNDEFINED_MAX_NUM_FIELDS"`
}

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
	undefined_cur_num_fields int64
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

	var undefined_config_obj UndefinedConfig
	var default_keep_fields string
	var extra_keep_fields string
	var tmp_keep_empty_fields string
	if config, err := os.Open(undefined_config); err == nil {
		defer config.Close()

		config_read, _ := ioutil.ReadAll(config)
		json.Unmarshal(config_read, &undefined_config_obj)

		undefined_debug = undefined_config_obj.Debug
		merge_json_log = undefined_config_obj.Merge_json_log
		use_undefined = undefined_config_obj.Use_undefined
		default_keep_fields = undefined_config_obj.Default_keep_fields
		extra_keep_fields = undefined_config_obj.Extra_keep_fields
		undefined_name = undefined_config_obj.Undefined_name
		tmp_keep_empty_fields = undefined_config_obj.Keep_empty_fields
		undefined_to_string = undefined_config_obj.Undefined_to_string
		undefined_dot_replace_char = undefined_config_obj.Undefined_dot_replace_char
		undefined_max_num_fields = undefined_config_obj.Undefined_max_num_fields
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

func replaceDotMoveUndefined(input map[string]interface{}, topPropLevel bool) (map[string]interface{},bool,bool) {
	replace_me := false
	has_undefined := false
	cp := make(map[string]interface{})
	for origkey, value := range input {
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
		valuearraymap, isarraymap := value.([]interface{})
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
			if undefined_cur_num_fields > 0 {
				if cp[undefined_name] == nil {
					subcp := make(map[string]interface{})
					cp[undefined_name] = subcp
				}
				if isarraymap {
					rval := replaceDotMoveUndefinedArray(valuearraymap)
					if len(rval) > 0 {
						cp[undefined_name].(map[string]interface{})[key] = rval
					}
				} else if ismap {
					rval, _, _ := replaceDotMoveUndefined(valuemap, false)
					if len(rval) > 0 {
						cp[undefined_name].(map[string]interface{})[key] = rval
					}
				} else {
					cp[undefined_name].(map[string]interface{})[key] = value
				}
				undefined_cur_num_fields--
				replace_me = true
				has_undefined = true
			}
		} else if isarraymap {
			rval := replaceDotMoveUndefinedArray(valuearraymap)
			cp[key] = rval
		} else if ismap {
			rval, _, _ := replaceDotMoveUndefined(valuemap, false)
			cp[key] = rval
		} else {
			cp[key] = value
		}
	}
	return cp, replace_me, has_undefined
}

func replaceDotMoveUndefinedArray(inputs []interface{}) []interface{} {
	cp := make([]interface{}, 0)
	for _, input := range inputs {
		valuemap, ismap := input.(map[string]interface{})
		valuearraymap, isarraymap := input.([]interface{})
		if ismap {
			rval, _, _ := replaceDotMoveUndefined(valuemap, false)
			cp = append(cp, rval)
		} else if isarraymap {
			rval := replaceDotMoveUndefinedArray(valuearraymap)
			cp = append(cp, rval)
		} else {
			fmt.Fprintln(logfile, "Error:", input, " is not a map.  Ignoring...")
		}
	}
	return cp
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
			fmt.Fprintln(logfile, "No Action Needed for ", rawStr)
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
			fmt.Fprintln(logfile, "Result is String: ", rawStr)
			fmt.Println(noChanges)
			continue
		}
		if jsonCopyMap["$!"] == nil {
			jsonCopyMap["$!"] = make(map[string]interface{})
		}
		undefined_cur_num_fields = undefined_max_num_fields
		all, replace_me, has_undefined := replaceDotMoveUndefined(topval, true)
		if !replace_me {
			fmt.Fprintln(logfile, "No Need to Replace for ", rawStr)
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
