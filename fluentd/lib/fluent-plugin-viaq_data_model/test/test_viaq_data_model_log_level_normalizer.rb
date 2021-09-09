#
# Fluentd Viaq Data Model Filter Plugin - Ensure records coming from Fluentd
# use the correct Viaq data model formatting and fields.
#
# Copyright 2016 Red Hat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
#require_relative '../helper'
require 'fluent/test'
require 'test/unit/rr'

require 'fluent/plugin/viaq_data_model_log_level_normalizer'


class ViaqDataModelFilterTest < Test::Unit::TestCase
    include ViaqDataModel::LogLevelNormalizer

    message = "20150909 Warning message=problem level=error"
    checks = /(?<l0_warn>Warning|level=warn)|(?<l1_error>Error|level=error)/
    
    setup do
        @level_matcher = checks
    end

    sub_test_case '#normalize_level' do

        sub_test_case 'when evaluating JSON message' do

            record = {"message" => "20210909T12:15:09 Warning Some Warning message"}
            
            test "should normalize the record level to the value of the 'level' field" do
                record["level"] = "info"
                normalize_level!(record)
                assert_equal('info',record['level'])
            end
            
            test "should normalize the record level to one of the checks when there is no 'level' field" do
                newrecord = {"message" => "20210909T12:15:09 Warning Some Warning message"}
                normalize_level!(newrecord)
                assert_equal('warn', newrecord['level'])
            end
        end
    end

    sub_test_case '#extract_level_from_message' do
        
        sub_test_case 'should return nil' do

            test 'when the checks are nil' do
                assert_nil(extract_level_from_message("info", nil))
            end

            test 'when there is no match' do
                assert_nil(extract_level_from_message("123", checks))
            end
        end

        sub_test_case 'should return the first non-nil match'  do

            test 'when checking for multiple configured matches' do
              assert_equal("warn",extract_level_from_message(message, checks))
            end

            test 'when checking for multiple configured matches reversed' do
              altchecks = /^.*(?<l0_error>Error|level=error)|(?<l1_warn>Warning|level=warn).*$/
              assert_equal("error",extract_level_from_message(message, altchecks))
            end

            test 'when checking a message that only matches a later matcher' do
              assert_equal("error",extract_level_from_message("Error", checks))
            end
        end

    end
end