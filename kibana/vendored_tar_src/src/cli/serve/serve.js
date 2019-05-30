'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

exports.default = function (program) {
  const command = program.command('serve');

  command.description('Run the kibana server').collectUnknownOptions().option('-e, --elasticsearch <uri1,uri2>', 'Elasticsearch instances').option('-c, --config <path>', 'Path to the config file, can be changed with the CONFIG_PATH environment variable as well. ' + 'Use multiple --config args to include multiple config files.', configPathCollector, [(0, _path2.getConfig)()]).option('-p, --port <port>', 'The port to bind to', parseInt).option('-q, --quiet', 'Prevent all logging except errors').option('-Q, --silent', 'Prevent all logging').option('--verbose', 'Turns on verbose logging').option('-H, --host <host>', 'The host to bind to').option('-l, --log-file <path>', 'The file to log to').option('--plugin-dir <path>', 'A path to scan for plugins, this can be specified multiple ' + 'times to specify multiple directories', pluginDirCollector, [(0, _utils.fromRoot)('plugins'), (0, _utils.fromRoot)('src/legacy/core_plugins')]).option('--plugin-path <path>', 'A path to a plugin which should be included by the server, ' + 'this can be specified multiple times to specify multiple paths', pluginPathCollector, []).option('--plugins <path>', 'an alias for --plugin-dir', pluginDirCollector).option('--optimize', 'Optimize and then stop the server');

  if (XPACK_OPTIONAL) {
    command.option('--oss', 'Start Kibana without X-Pack');
  }

  if (CAN_CLUSTER) {
    command.option('--dev', 'Run the server with development mode defaults').option('--open', 'Open a browser window to the base url after the server is started').option('--ssl', 'Run the dev server using HTTPS').option('--no-base-path', 'Don\'t put a proxy in front of the dev server, which adds a random basePath').option('--no-watch', 'Prevents automatic restarts of the server in --dev mode');
  }

  command.action(async function (opts) {
    if (opts.dev) {
      try {
        const kbnDevConfig = (0, _utils.fromRoot)('config/kibana.dev.yml');
        if ((0, _fs.statSync)(kbnDevConfig).isFile()) {
          opts.config.push(kbnDevConfig);
        }
      } catch (err) {
        // ignore, kibana.dev.yml does not exist
      }
    }

    const unknownOptions = this.getUnknownOptions();
    await (0, _server.bootstrap)({
      configs: [].concat(opts.config || []),
      cliArgs: {
        dev: !!opts.dev,
        open: !!opts.open,
        envName: unknownOptions.env ? unknownOptions.env.name : undefined,
        quiet: !!opts.quiet,
        silent: !!opts.silent,
        watch: !!opts.watch,
        basePath: !!opts.basePath,
        optimize: !!opts.optimize
      },
      features: {
        isClusterModeSupported: CAN_CLUSTER,
        isOssModeSupported: XPACK_OPTIONAL,
        isXPackInstalled: XPACK_INSTALLED
      },
      applyConfigOverrides: rawConfig => applyConfigOverrides(rawConfig, opts, unknownOptions)
    });
  });
};

var _lodash = require('lodash');

var _lodash2 = _interopRequireDefault(_lodash);

var _fs = require('fs');

var _path = require('path');

var _utils = require('../../utils');

var _path2 = require('../../server/path');

var _server = require('../../core/server');

var _read_keystore = require('./read_keystore');

var _dev_ssl = require('../dev_ssl');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

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

function canRequire(path) {
  try {
    require.resolve(path);
    return true;
  } catch (error) {
    if (error.code === 'MODULE_NOT_FOUND') {
      return false;
    } else {
      throw error;
    }
  }
}

function isSymlinkTo(link, dest) {
  try {
    const stat = (0, _fs.lstatSync)(link);
    return stat.isSymbolicLink() && (0, _fs.realpathSync)(link) === dest;
  } catch (error) {
    if (error.code !== 'ENOENT') {
      throw error;
    }
  }
}

const CLUSTER_MANAGER_PATH = (0, _path.resolve)(__dirname, '../cluster/cluster_manager');
const CAN_CLUSTER = canRequire(CLUSTER_MANAGER_PATH);

// xpack is installed in both dev and the distributable, it's optional if
// install is a link to the source, not an actual install
const XPACK_INSTALLED_DIR = (0, _path.resolve)(__dirname, '../../../node_modules/x-pack');
const XPACK_SOURCE_DIR = (0, _path.resolve)(__dirname, '../../../x-pack');
const XPACK_INSTALLED = canRequire(XPACK_INSTALLED_DIR);
const XPACK_OPTIONAL = isSymlinkTo(XPACK_INSTALLED_DIR, XPACK_SOURCE_DIR);

const pathCollector = function () {
  const paths = [];
  return function (path) {
    paths.push((0, _path.resolve)(process.cwd(), path));
    return paths;
  };
};

const configPathCollector = pathCollector();
const pluginDirCollector = pathCollector();
const pluginPathCollector = pathCollector();

function applyConfigOverrides(rawConfig, opts, extraCliOptions) {
  const set = _lodash2.default.partial(_lodash2.default.set, rawConfig);
  const get = _lodash2.default.partial(_lodash2.default.get, rawConfig);
  const has = _lodash2.default.partial(_lodash2.default.has, rawConfig);
  const merge = _lodash2.default.partial(_lodash2.default.merge, rawConfig);

  if (opts.dev) {
    set('env', 'development');
    set('optimize.watch', true);

    if (!has('elasticsearch.username')) {
      set('elasticsearch.username', 'elastic');
    }

    if (!has('elasticsearch.password')) {
      set('elasticsearch.password', 'changeme');
    }

    if (opts.ssl) {
      set('server.ssl.enabled', true);
    }

    if (opts.ssl && !has('server.ssl.certificate') && !has('server.ssl.key')) {
      set('server.ssl.certificate', _dev_ssl.DEV_SSL_CERT_PATH);
      set('server.ssl.key', _dev_ssl.DEV_SSL_KEY_PATH);
    }
  }

  if (opts.elasticsearch) set('elasticsearch.hosts', opts.elasticsearch.split(','));
  if (opts.port) set('server.port', opts.port);
  if (opts.host) set('server.host', opts.host);
  if (opts.quiet) set('logging.quiet', true);
  if (opts.silent) set('logging.silent', true);
  if (opts.verbose) set('logging.verbose', true);
  if (opts.logFile) set('logging.dest', opts.logFile);

  if (opts.optimize) {
    set('server.autoListen', false);
    set('plugins.initialize', false);
  }

  set('plugins.scanDirs', _lodash2.default.compact([].concat(get('plugins.scanDirs'), opts.pluginDir)));

  set('plugins.paths', _lodash2.default.compact([].concat(get('plugins.paths'), opts.pluginPath, XPACK_INSTALLED && (!XPACK_OPTIONAL || !opts.oss) ? [XPACK_INSTALLED_DIR] : [])));

  merge(extraCliOptions);
  merge((0, _read_keystore.readKeystore)(get('path.data')));

  return rawConfig;
}

module.exports = exports['default'];