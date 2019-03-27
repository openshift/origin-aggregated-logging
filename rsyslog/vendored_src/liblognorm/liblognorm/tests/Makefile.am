check_PROGRAMS = json_eq
# re-enable if we really need the c program check check_PROGRAMS = json_eq user_test
json_eq_self_sources = json_eq.c
json_eq_SOURCES = $(json_eq_self_sources)
json_eq_CPPFLAGS =  $(JSON_C_CFLAGS) $(WARN_CFLAGS) -I$(top_srcdir)/src
json_eq_LDADD = $(JSON_C_LIBS) -lm -lestr
json_eq_LDFLAGS = -no-install

#user_test_SOURCES = user_test.c
#user_test_CPPFLAGS = $(LIBLOGNORM_CFLAGS) $(JSON_C_CFLAGS) $(LIBESTR_CFLAGS)
#user_test_LDADD = $(JSON_C_LIBS) $(LIBLOGNORM_LIBS) $(LIBESTR_LIBS) ../compat/compat.la 
#user_test_LDFLAGS = -no-install

# The following tests are for the new pdag-based engine (v2+).
#
# There are some notes due:
#
# removed field_float_with_invalid_ruledef.sh because test is not valid.
# more info: https://github.com/rsyslog/liblognorm/issues/98
# note that probably the other currently disable *_invalid_*.sh
# tests are also affected.
#
# there seems to be a problem with some format in cisco-interface-spec
# Probably this was just not seen in v1, because of some impreciseness
# in the ptree normalizer. Pushing equivalent v2 test back until v2
# implementation is further developed.
TESTS_SHELLSCRIPTS = \
	usrdef_simple.sh \
	usrdef_two.sh \
	usrdef_twotypes.sh \
	usrdef_actual1.sh \
	usrdef_ipaddr.sh \
	usrdef_ipaddr_dotdot.sh \
	usrdef_ipaddr_dotdot2.sh \
	usrdef_ipaddr_dotdot3.sh \
	missing_line_ending.sh \
	lognormalizer-invld-call.sh \
	string_rb_simple.sh \
	string_rb_simple_2_lines.sh \
	names.sh \
	literal.sh \
	include.sh \
	include_RULEBASES.sh \
	seq_simple.sh \
	runaway_rule.sh \
	runaway_rule_comment.sh \
	annotate.sh \
	alternative_simple.sh \
	alternative_three.sh \
	alternative_nested.sh \
	alternative_segfault.sh \
	repeat_very_simple.sh \
	repeat_simple.sh \
	repeat_mismatch_in_while.sh \
	repeat_while_alternative.sh \
	repeat_alternative_nested.sh \
	parser_prios.sh \
	parser_whitespace.sh \
	parser_whitespace_jsoncnf.sh \
	parser_LF.sh \
	parser_LF_jsoncnf.sh \
	strict_prefix_actual_sample1.sh \
	strict_prefix_matching_1.sh \
	strict_prefix_matching_2.sh \
	field_string.sh \
	field_string_perm_chars.sh \
	field_number.sh \
	field_number-fmt_number.sh \
	field_number_maxval.sh \
	field_hexnumber.sh \
	field_hexnumber-fmt_number.sh \
	field_hexnumber_jsoncnf.sh \
	field_hexnumber_range.sh \
	field_hexnumber_range_jsoncnf.sh \
	rule_last_str_short.sh \
	field_mac48.sh \
	field_mac48_jsoncnf.sh \
	field_name_value.sh \
	field_name_value_jsoncnf.sh \
	field_kernel_timestamp.sh \
	field_kernel_timestamp_jsoncnf.sh \
	field_whitespace.sh \
	rule_last_str_long.sh \
	field_whitespace_jsoncnf.sh \
	field_rest.sh \
	field_rest_jsoncnf.sh \
	field_json.sh \
	field_json_jsoncnf.sh \
	field_cee-syslog.sh \
	field_cee-syslog_jsoncnf.sh \
	field_ipv6.sh \
	field_ipv6_jsoncnf.sh \
	field_v2-iptables.sh \
	field_v2-iptables_jsoncnf.sh \
	field_cef.sh \
	field_cef_jsoncnf.sh \
	field_checkpoint-lea.sh \
	field_checkpoint-lea_jsoncnf.sh \
	field_duration.sh \
	field_duration_jsoncnf.sh \
	field_float.sh \
	field_float-fmt_number.sh \
	field_float_jsoncnf.sh \
	field_rfc5424timestamp-fmt_timestamp-unix.sh \
	field_rfc5424timestamp-fmt_timestamp-unix-ms.sh \
	very_long_logline_jsoncnf.sh

# now come tests for the legacy (v1) engine
TESTS_SHELLSCRIPTS += \
	missing_line_ending_v1.sh \
	runaway_rule_v1.sh \
	runaway_rule_comment_v1.sh \
	field_hexnumber_v1.sh \
	field_mac48_v1.sh \
	field_name_value_v1.sh \
	field_kernel_timestamp_v1.sh \
	field_whitespace_v1.sh \
	field_rest_v1.sh \
	field_json_v1.sh \
	field_cee-syslog_v1.sh \
	field_ipv6_v1.sh \
	field_v2-iptables_v1.sh \
	field_cef_v1.sh \
	field_checkpoint-lea_v1.sh \
	field_duration_v1.sh \
	field_float_v1.sh \
	field_cee-syslog_v1.sh \
	field_tokenized.sh \
	field_tokenized_with_invalid_ruledef.sh \
	field_recursive.sh \
	field_tokenized_recursive.sh \
	field_interpret.sh \
	field_interpret_with_invalid_ruledef.sh \
	field_descent.sh \
	field_descent_with_invalid_ruledef.sh \
	field_suffixed.sh \
	field_suffixed_with_invalid_ruledef.sh \
	field_cisco-interface-spec.sh \
	field_float_with_invalid_ruledef.sh \
	very_long_logline.sh


#re-add to TESTS if needed: user_test
TESTS = \
	$(TESTS_SHELLSCRIPTS)

REGEXP_TESTS = \
	field_regex_default_group_parse_and_return.sh \
	field_regex_invalid_args.sh \
	field_regex_with_consume_group.sh \
	field_regex_with_consume_group_and_return_group.sh \
	field_regex_with_negation.sh \
	field_tokenized_with_regex.sh \
	field_regex_while_regex_support_is_disabled.sh

EXTRA_DIST = exec.sh \
	$(TESTS_SHELLSCRIPTS) \
	$(REGEXP_TESTS) \
	$(json_eq_self_sources) \
	$(user_test_SOURCES)

if ENABLE_REGEXP
TESTS += $(REGEXP_TESTS)
endif
