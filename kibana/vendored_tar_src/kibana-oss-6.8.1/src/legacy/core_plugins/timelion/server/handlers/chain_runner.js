'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = chainRunner;

var _lodash = require('lodash');

var _lodash2 = _interopRequireDefault(_lodash);

var _bluebird = require('bluebird');

var _bluebird2 = _interopRequireDefault(_bluebird);

var _i18n = require('@kbn/i18n');

var _parse_sheet = require('./lib/parse_sheet.js');

var _parse_sheet2 = _interopRequireDefault(_parse_sheet);

var _date_math = require('../lib/date_math.js');

var _date_math2 = _interopRequireDefault(_date_math);

var _reposition_arguments = require('./lib/reposition_arguments.js');

var _reposition_arguments2 = _interopRequireDefault(_reposition_arguments);

var _index_arguments = require('./lib/index_arguments.js');

var _index_arguments2 = _interopRequireDefault(_index_arguments);

var _validate_time = require('./lib/validate_time.js');

var _validate_time2 = _interopRequireDefault(_validate_time);

var _lib = require('../../common/lib');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function chainRunner(tlConfig) {
  const preprocessChain = require('./lib/preprocess_chain')(tlConfig);

  let queryCache = {};
  const stats = {};
  let sheet;

  function throwWithCell(cell, exception) {
    throw new Error(' in cell #' + (cell + 1) + ': ' + exception.message);
  }

  // Invokes a modifier function, resolving arguments into series as needed
  function invoke(fnName, args) {
    const functionDef = tlConfig.server.plugins.timelion.getFunction(fnName);

    function resolveArgument(item) {
      if (Array.isArray(item)) {
        return _bluebird2.default.all(_lodash2.default.map(item, resolveArgument));
      }

      if (_lodash2.default.isObject(item)) {
        switch (item.type) {
          case 'function':
            {
              const itemFunctionDef = tlConfig.server.plugins.timelion.getFunction(item.function);
              if (itemFunctionDef.cacheKey && queryCache[itemFunctionDef.cacheKey(item)]) {
                stats.queryCount++;
                return _bluebird2.default.resolve(_lodash2.default.cloneDeep(queryCache[itemFunctionDef.cacheKey(item)]));
              }
              return invoke(item.function, item.arguments);
            }
          case 'reference':
            {
              let reference;
              if (item.series) {
                reference = sheet[item.plot - 1][item.series - 1];
              } else {
                reference = {
                  type: 'chainList',
                  list: sheet[item.plot - 1]
                };
              }
              return invoke('first', [reference]);
            }
          case 'chain':
            return invokeChain(item);
          case 'chainList':
            return resolveChainList(item.list);
          case 'literal':
            return item.value;
          case 'requestList':
          case 'seriesList':
            return item;
        }
        throw new Error(_i18n.i18n.translate('timelion.serverSideErrors.unknownArgumentTypeErrorMessage', {
          defaultMessage: 'Argument type not supported: {argument}',
          values: {
            argument: JSON.stringify(item)
          }
        }));
      } else {
        return item;
      }
    }

    args = (0, _reposition_arguments2.default)(functionDef, args);

    args = _lodash2.default.map(args, resolveArgument);

    return _bluebird2.default.all(args).then(function (args) {
      args.byName = (0, _index_arguments2.default)(functionDef, args);
      return functionDef.fn(args, tlConfig);
    });
  }

  function invokeChain(chainObj, result) {
    if (chainObj.chain.length === 0) return result[0];

    const chain = _lodash2.default.clone(chainObj.chain);
    const link = chain.shift();

    let promise;
    if (link.type === 'chain') {
      promise = invokeChain(link);
    } else if (!result) {
      promise = invoke('first', [link]);
    } else {
      const args = link.arguments ? result.concat(link.arguments) : result;
      promise = invoke(link.function, args);
    }

    return promise.then(function (result) {
      return invokeChain({ type: 'chain', chain: chain }, [result]);
    });
  }

  function resolveChainList(chainList) {
    const seriesList = _lodash2.default.map(chainList, function (chain) {
      const values = invoke('first', [chain]);
      return values.then(function (args) {
        return args;
      });
    });
    return _bluebird2.default.all(seriesList).then(function (args) {
      const list = _lodash2.default.chain(args).pluck('list').flatten().value();
      const seriesList = _lodash2.default.merge.apply(this, _lodash2.default.flatten([{}, args]));
      seriesList.list = list;
      return seriesList;
    });
  }

  function preProcessSheet(sheet) {

    let queries = {};
    _lodash2.default.each(sheet, function (chainList, i) {
      try {
        const queriesInCell = _lodash2.default.mapValues(preprocessChain(chainList), function (val) {
          val.cell = i;
          return val;
        });
        queries = _lodash2.default.extend(queries, queriesInCell);
      } catch (e) {
        throwWithCell(i, e);
      }
    });
    queries = _lodash2.default.values(queries);

    const promises = _lodash2.default.chain(queries).values().map(function (query) {
      return invoke(query.function, query.arguments);
    }).value();

    return _bluebird2.default.settle(promises).then(function (resolvedDatasources) {

      stats.queryTime = new Date().getTime();

      _lodash2.default.each(queries, function (query, i) {
        const functionDef = tlConfig.server.plugins.timelion.getFunction(query.function);
        const resolvedDatasource = resolvedDatasources[i];

        if (resolvedDatasource.isRejected()) {
          if (resolvedDatasource.reason().isBoom) {
            throw resolvedDatasource.reason();
          } else {
            throwWithCell(query.cell, resolvedDatasource.reason());
          }
        }

        queryCache[functionDef.cacheKey(query)] = resolvedDatasource.value();
      });

      stats.cacheCount = _lodash2.default.keys(queryCache).length;
      return sheet;
    });
  }

  function processRequest(request) {
    if (!request) throw new Error('Empty request body');

    (0, _validate_time2.default)(request.time, tlConfig);

    tlConfig.time = request.time;
    tlConfig.time.to = (0, _date_math2.default)(request.time.to, true).valueOf();
    tlConfig.time.from = (0, _date_math2.default)(request.time.from).valueOf();
    tlConfig.time.interval = (0, _lib.calculateInterval)(tlConfig.time.from, tlConfig.time.to, tlConfig.settings['timelion:target_buckets'] || 200, tlConfig.time.interval, tlConfig.settings['timelion:min_interval'] || '1ms');

    tlConfig.setTargetSeries();

    stats.invokeTime = new Date().getTime();
    stats.queryCount = 0;
    queryCache = {};

    // This is setting the "global" sheet, required for resolving references
    sheet = (0, _parse_sheet2.default)(request.sheet);
    return preProcessSheet(sheet).then(function () {
      return _lodash2.default.map(sheet, function (chainList, i) {
        return resolveChainList(chainList).then(function (seriesList) {
          stats.sheetTime = new Date().getTime();
          return seriesList;
        }).catch(function (e) {
          throwWithCell(i, e);
        });
      });
    });
  }

  return {
    processRequest: processRequest,
    getStats: function () {
      return stats;
    }
  };
} /*
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

module.exports = exports['default'];