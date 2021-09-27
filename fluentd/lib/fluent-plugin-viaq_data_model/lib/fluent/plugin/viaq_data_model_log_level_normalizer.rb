#
# Fluentd ViaQ data model Filter Plugin
#
# Copyright 2021 Red Hat, Inc.
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
module ViaqDataModel
# https://github.com/ViaQ/elasticsearch-templates/blob/master/namespaces/_default_.yml#L63
    NORMAL_LEVELS = {
        'emerg'    => 'emerg',
        'panic'    => 'emerg',
        'alert'    => 'alert',
        'crit'     => 'crit',
        'critical' => 'crit',
        'err'      => 'err',
        'error'    => 'err',
        'warning'  => 'warning',
        'warn'     => 'warning',
        'notice'   => 'notice',
        'info'     => 'info',
        'debug'    => 'debug',
        'trace'    => 'trace',
        'unknown'  => 'unknown',
    }
    # numeric levels for the PRIORITY field
    PRIORITY_LEVELS = {
        0 => 'emerg',
        1 => 'alert',
        2 => 'crit',
        3 => 'err',
        4 => 'warning',
        5 => 'notice',
        6 => 'info',
        7 => 'debug',
        8 => 'trace',
        9 => 'unknown',
        '0' => 'emerg',
        '1' => 'alert',
        '2' => 'crit',
        '3' => 'err',
        '4' => 'warning',
        '5' => 'notice',
        '6' => 'info',
        '7' => 'debug',
        '8' => 'trace',
        '9' => 'unknown',
    }

    module LogLevelNormalizer

        # normalize_level! attempts to convert all level values into a common format
        # on the output side.  It optionally takes a block for further processing as needed
        def normalize_level!(record, priority=nil)
            
            level = record['level']
            # if the record already has a level field, and it looks like one of our well
            # known values, convert it to the canonical normalized form - otherwise,
            # preserve the value in string format
            retlevel = nil 
            if !level.nil?
                unless (retlevel = NORMAL_LEVELS[level]) ||
                        (level.respond_to?(:downcase) && (retlevel = NORMAL_LEVELS[level.downcase]))
                    retlevel = level.to_s # don't know what it is - just convert to string
                end
            elsif !priority.nil?
              retlevel = PRIORITY_LEVELS[priority]
            end
            if record['message'] && retlevel.nil? 
                retlevel = extract_level_from_message(record['message'], @level_matcher)
            end
            record['level'] = retlevel || 'unknown'
        end

        # extract_level_from_message evaluates a message against a regex expression
        # that returns the first named group.  The named group is assumed to be
        # prefixed with the pattern: 'l[0-9]_' or nil if unmatched
        def extract_level_from_message(message, check)
            return nil unless check
            matches = check.match(message)
            if matches
                matches.named_captures.each do |key, value|
                    return key[3..-1] unless value.nil?
                end
            end
            return nil
        end

    end
end