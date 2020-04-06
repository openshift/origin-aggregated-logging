/*
 * Licensed to Elasticsearch B.V. under one or more contributor
 * license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright
 * ownership. Elasticsearch B.V. licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */
import * as tslib_1 from "tslib";
import { leastCommonMultiple } from '../../../utils/math';
import { parseEsInterval } from '../../../utils/parse_es_interval';
import { leastCommonInterval } from '../../lib/least_common_interval';
var EditorConfigProviderRegistry = /** @class */ (function () {
    function EditorConfigProviderRegistry() {
        this.providers = new Set();
    }
    EditorConfigProviderRegistry.prototype.register = function (configProvider) {
        this.providers.add(configProvider);
    };
    EditorConfigProviderRegistry.prototype.getConfigForAgg = function (aggType, indexPattern, aggConfig) {
        var configs = Array.from(this.providers).map(function (provider) {
            return provider(aggType, indexPattern, aggConfig);
        });
        return this.mergeConfigs(configs);
    };
    EditorConfigProviderRegistry.prototype.isTimeBaseParam = function (config) {
        return config.hasOwnProperty('default') && config.hasOwnProperty('timeBase');
    };
    EditorConfigProviderRegistry.prototype.isBaseParam = function (config) {
        return config.hasOwnProperty('base');
    };
    EditorConfigProviderRegistry.prototype.isFixedParam = function (config) {
        return config.hasOwnProperty('fixedValue');
    };
    EditorConfigProviderRegistry.prototype.mergeHidden = function (current, merged) {
        return Boolean(current.hidden || merged.hidden);
    };
    EditorConfigProviderRegistry.prototype.mergeHelp = function (current, merged) {
        if (!current.help) {
            return merged.help;
        }
        return merged.help ? merged.help + "\n\n" + current.help : current.help;
    };
    EditorConfigProviderRegistry.prototype.mergeFixedAndBase = function (current, merged, paramName) {
        if (this.isFixedParam(current) &&
            this.isFixedParam(merged) &&
            current.fixedValue !== merged.fixedValue) {
            // In case multiple configurations provided a fixedValue, these must all be the same.
            // If not we'll throw an error.
            throw new Error("Two EditorConfigProviders provided different fixed values for field " + paramName + ":\n          " + merged.fixedValue + " !== " + current.fixedValue);
        }
        if ((this.isFixedParam(current) && this.isBaseParam(merged)) ||
            (this.isBaseParam(current) && this.isFixedParam(merged))) {
            // In case one config tries to set a fixed value and another setting a base value,
            // we'll throw an error. This could be solved more elegantly, by allowing fixedValues
            // that are the multiple of the specific base value, but since there is no use-case for that
            // right now, this isn't implemented.
            throw new Error("Tried to provide a fixedValue and a base for param " + paramName + ".");
        }
        if (this.isBaseParam(current) && this.isBaseParam(merged)) {
            // In case where both had interval values, just use the least common multiple between both interval
            return {
                base: leastCommonMultiple(current.base, merged.base),
            };
        }
        // In this case we haven't had a fixed value of base for that param yet, we use the one specified
        // in the current config
        if (this.isFixedParam(current)) {
            return {
                fixedValue: current.fixedValue,
            };
        }
        if (this.isBaseParam(current)) {
            return {
                base: current.base,
            };
        }
        return {};
    };
    EditorConfigProviderRegistry.prototype.mergeTimeBase = function (current, merged, paramName) {
        if (current.default !== current.timeBase) {
            throw new Error("Tried to provide differing default and timeBase values for " + paramName + ".");
        }
        if (this.isTimeBaseParam(current) && this.isTimeBaseParam(merged)) {
            // In case both had where interval values, just use the least common multiple between both intervals
            try {
                var timeBase = leastCommonInterval(current.timeBase, merged.timeBase);
                return {
                    default: timeBase,
                    timeBase: timeBase,
                };
            }
            catch (e) {
                throw e;
            }
        }
        if (this.isTimeBaseParam(current)) {
            try {
                parseEsInterval(current.timeBase);
                return {
                    default: current.timeBase,
                    timeBase: current.timeBase,
                };
            }
            catch (e) {
                throw e;
            }
        }
        return {};
    };
    EditorConfigProviderRegistry.prototype.mergeConfigs = function (configs) {
        var _this = this;
        return configs.reduce(function (output, conf) {
            Object.entries(conf).forEach(function (_a) {
                var _b = tslib_1.__read(_a, 2), paramName = _b[0], paramConfig = _b[1];
                if (!output[paramName]) {
                    output[paramName] = {};
                }
                output[paramName] = tslib_1.__assign({ hidden: _this.mergeHidden(paramConfig, output[paramName]), help: _this.mergeHelp(paramConfig, output[paramName]) }, (_this.isTimeBaseParam(paramConfig)
                    ? _this.mergeTimeBase(paramConfig, output[paramName], paramName)
                    : _this.mergeFixedAndBase(paramConfig, output[paramName], paramName)));
            });
            return output;
        }, {});
    };
    return EditorConfigProviderRegistry;
}());
var editorConfigProviders = new EditorConfigProviderRegistry();
export { editorConfigProviders, EditorConfigProviderRegistry };
