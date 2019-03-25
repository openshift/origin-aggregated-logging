#include "config.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <json.h>
#include "internal.h"


typedef struct json_object obj;

static int eq(obj* expected, obj* actual);

static int obj_eq(obj* expected, obj* actual) {
	int eql = 1;
	struct json_object_iterator it = json_object_iter_begin(expected);
	struct json_object_iterator itEnd = json_object_iter_end(expected);
	while (!json_object_iter_equal(&it, &itEnd)) {
		obj *actual_val;
		json_object_object_get_ex(actual, json_object_iter_peek_name(&it), &actual_val);
		eql &= eq(json_object_iter_peek_value(&it), actual_val);
		json_object_iter_next(&it);
	}
	return eql;
}

static int arr_eq(obj* expected, obj* actual) {
	int eql = 1;
	int expected_len = json_object_array_length(expected);
	int actual_len = json_object_array_length(actual);
	if (expected_len != actual_len) return 0;
		for (int i = 0; i < expected_len; i++) {
			obj* exp = json_object_array_get_idx(expected, i);
			obj* act = json_object_array_get_idx(actual, i);
			eql &= eq(exp, act);
		}
	return eql;
}

static int str_eq(obj* expected, obj* actual) {
	const char* exp_str = json_object_to_json_string(expected);
	const char* act_str = json_object_to_json_string(actual);
	return strcmp(exp_str, act_str) == 0;
}

static int eq(obj* expected, obj* actual) {
	if (expected == NULL && actual == NULL) {
		return 1;
	} else if (expected == NULL) {
		return 0;
	} else if (actual == NULL) {
		return 0;
	}
	enum json_type expected_type = json_object_get_type(expected);
	enum json_type actual_type = json_object_get_type(actual);
	if (expected_type != actual_type) return 0;
	switch(expected_type) {
	case json_type_null:
		return 1;
	case json_type_boolean:
		return json_object_get_boolean(expected) == json_object_get_boolean(actual);
	case json_type_double:
		return (fabs(json_object_get_double(expected) - json_object_get_double(actual)) < 0.001);
	case json_type_int:
		return json_object_get_int64(expected) == json_object_get_int64(actual);
	case json_type_object:
		return obj_eq(expected, actual);
	case json_type_array:
		return arr_eq(expected, actual);
	case json_type_string:
		return str_eq(expected, actual);
	default:
		fprintf(stderr, "unexpected type in %s:%d\n", __FILE__, __LINE__);
		abort();
	}
	return 0;
}

int main(int argc, char** argv) {
	if (argc != 3) {
		fprintf(stderr, "expected and actual json not given, number of args was: %d\n", argc);
		exit(100);
	}
	obj* expected = json_tokener_parse(argv[1]);
	obj* actual = json_tokener_parse(argv[2]);
	int result = eq(expected, actual) ? 0 : 1;
	json_object_put(expected);
	json_object_put(actual);
	if (result != 0) {
		printf("JSONs weren't equal. \n\tExpected: \n\t\t%s\n\tActual: \n\t\t%s\n", argv[1], argv[2]);
	}
	return result;
}
