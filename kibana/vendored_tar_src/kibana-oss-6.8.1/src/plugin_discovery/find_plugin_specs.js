'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.findPluginSpecs = findPluginSpecs;

var _rxjs = require('rxjs');

var Rx = _interopRequireWildcard(_rxjs);

var _operators = require('rxjs/operators');

var _fs = require('fs');

var _config = require('../server/config');

var _plugin_config = require('./plugin_config');

var _plugin_pack = require('./plugin_pack');

var _errors = require('./errors');

function _interopRequireWildcard(obj) { if (obj && obj.__esModule) { return obj; } else { var newObj = {}; if (obj != null) { for (var key in obj) { if (Object.prototype.hasOwnProperty.call(obj, key)) newObj[key] = obj[key]; } } newObj.default = obj; return newObj; } }

function defaultConfig(settings) {
  return _config.Config.withDefaultSchema((0, _config.transformDeprecations)(settings));
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

function bufferAllResults(observable) {
  return observable.pipe(
  // buffer all results into a single array
  (0, _operators.toArray)(),
  // merge the array back into the stream when complete
  (0, _operators.mergeMap)(array => array));
}

/**
 * Determine a distinct value for each result from find$
 * so they can be deduplicated
 * @param  {{error?,pack?}} result
 * @return {Any}
 */
function getDistinctKeyForFindResult(result) {
  // errors are distinct by their message
  if (result.error) {
    return result.error.message;
  }

  // packs are distinct by their absolute and real path
  if (result.packageJson) {
    return (0, _fs.realpathSync)(result.packageJson.directoryPath);
  }

  // non error/pack results shouldn't exist, but if they do they are all unique
  return result;
}

function groupSpecsById(specs) {
  const specsById = new Map();
  for (const spec of specs) {
    const id = spec.getId();
    if (specsById.has(id)) {
      specsById.get(id).push(spec);
    } else {
      specsById.set(id, [spec]);
    }
  }
  return specsById;
}

/**
 *  Creates a collection of observables for discovering pluginSpecs
 *  using Kibana's defaults, settings, and config service
 *
 *  @param {Object} settings
 *  @param {ConfigService} [configToMutate] when supplied **it is mutated** to
 *  include the config from discovered plugin specs
 *  @return {Object<name,Rx>}
 */
function findPluginSpecs(settings, configToMutate) {
  const config$ = Rx.defer(async () => {
    if (configToMutate) {
      return configToMutate;
    }

    return defaultConfig(settings);
  }).pipe((0, _operators.shareReplay)());

  // find plugin packs in configured paths/dirs
  const packageJson$ = config$.pipe((0, _operators.mergeMap)(config => Rx.merge(...config.get('plugins.paths').map(_plugin_pack.createPackageJsonAtPath$), ...config.get('plugins.scanDirs').map(_plugin_pack.createPackageJsonsInDirectory$))), (0, _operators.distinct)(getDistinctKeyForFindResult), (0, _operators.share)());

  const pack$ = (0, _plugin_pack.createPack$)(packageJson$).pipe((0, _operators.share)());

  const extendConfig$ = config$.pipe((0, _operators.mergeMap)(config => pack$.pipe(
  // get the specs for each found plugin pack
  (0, _operators.mergeMap)(({ pack }) => pack ? pack.getPluginSpecs() : []),
  // make sure that none of the plugin specs have conflicting ids, fail
  // early if conflicts detected or merge the specs back into the stream
  (0, _operators.toArray)(), (0, _operators.mergeMap)(allSpecs => {
    for (const [id, specs] of groupSpecsById(allSpecs)) {
      if (specs.length > 1) {
        throw new Error(`Multiple plugins found with the id "${id}":\n${specs.map(spec => `  - ${id} at ${spec.getPath()}`).join('\n')}`);
      }
    }

    return allSpecs;
  }), (0, _operators.mergeMap)(async spec => {
    // extend the config service with this plugin spec and
    // collect its deprecations messages if some of its
    // settings are outdated
    const deprecations = [];
    await (0, _plugin_config.extendConfigService)(spec, config, settings, message => {
      deprecations.push({ spec, message });
    });

    return {
      spec,
      deprecations
    };
  }),
  // extend the config with all plugins before determining enabled status
  bufferAllResults, (0, _operators.map)(({ spec, deprecations }) => {
    const isRightVersion = spec.isVersionCompatible(config.get('pkg.version'));
    const enabled = isRightVersion && spec.isEnabled(config);
    return {
      config,
      spec,
      deprecations,
      enabledSpecs: enabled ? [spec] : [],
      disabledSpecs: enabled ? [] : [spec],
      invalidVersionSpecs: isRightVersion ? [] : [spec]
    };
  }),
  // determine which plugins are disabled before actually removing things from the config
  bufferAllResults, (0, _operators.tap)(result => {
    for (const spec of result.disabledSpecs) {
      (0, _plugin_config.disableConfigExtension)(spec, config);
    }
  }))), (0, _operators.share)());

  return {
    // package JSONs found when searching configure paths
    packageJson$: packageJson$.pipe((0, _operators.mergeMap)(result => result.packageJson ? [result.packageJson] : [])),

    // plugin packs found when searching configured paths
    pack$: pack$.pipe((0, _operators.mergeMap)(result => result.pack ? [result.pack] : [])),

    // errors caused by invalid directories of plugin directories
    invalidDirectoryError$: pack$.pipe((0, _operators.mergeMap)(result => (0, _errors.isInvalidDirectoryError)(result.error) ? [result.error] : [])),

    // errors caused by directories that we expected to be plugin but were invalid
    invalidPackError$: pack$.pipe((0, _operators.mergeMap)(result => (0, _errors.isInvalidPackError)(result.error) ? [result.error] : [])),

    otherError$: pack$.pipe((0, _operators.mergeMap)(result => isUnhandledError(result.error) ? [result.error] : [])),

    // { spec, message } objects produced when transforming deprecated
    // settings for a plugin spec
    deprecation$: extendConfig$.pipe((0, _operators.mergeMap)(result => result.deprecations)),

    // the config service we extended with all of the plugin specs,
    // only emitted once it is fully extended by all
    extendedConfig$: extendConfig$.pipe((0, _operators.mergeMap)(result => result.config), (0, _operators.filter)(Boolean), (0, _operators.last)()),

    // all enabled PluginSpec objects
    spec$: extendConfig$.pipe((0, _operators.mergeMap)(result => result.enabledSpecs)),

    // all disabled PluginSpec objects
    disabledSpec$: extendConfig$.pipe((0, _operators.mergeMap)(result => result.disabledSpecs)),

    // all PluginSpec objects that were disabled because their version was incompatible
    invalidVersionSpec$: extendConfig$.pipe((0, _operators.mergeMap)(result => result.invalidVersionSpecs))
  };
}

function isUnhandledError(error) {
  return error != null && !(0, _errors.isInvalidDirectoryError)(error) && !(0, _errors.isInvalidPackError)(error);
}