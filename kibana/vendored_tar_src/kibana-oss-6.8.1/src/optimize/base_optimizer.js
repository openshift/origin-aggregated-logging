'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends = Object.assign || function (target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i]; for (var key in source) { if (Object.prototype.hasOwnProperty.call(source, key)) { target[key] = source[key]; } } } return target; }; /*
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

var _fs = require('fs');

var _os = require('os');

var _os2 = _interopRequireDefault(_os);

var _boom = require('boom');

var _boom2 = _interopRequireDefault(_boom);

var _miniCssExtractPlugin = require('mini-css-extract-plugin');

var _miniCssExtractPlugin2 = _interopRequireDefault(_miniCssExtractPlugin);

var _terserWebpackPlugin = require('terser-webpack-plugin');

var _terserWebpackPlugin2 = _interopRequireDefault(_terserWebpackPlugin);

var _webpack = require('webpack');

var _webpack2 = _interopRequireDefault(_webpack);

var _Stats = require('webpack/lib/Stats');

var _Stats2 = _interopRequireDefault(_Stats);

var _threadLoader = require('thread-loader');

var threadLoader = _interopRequireWildcard(_threadLoader);

var _webpackMerge = require('webpack-merge');

var _webpackMerge2 = _interopRequireDefault(_webpackMerge);

var _dynamic_dll_plugin = require('./dynamic_dll_plugin');

var _lodash = require('lodash');

var _utils = require('../utils');

var _public_path_placeholder = require('./public_path_placeholder');

function _interopRequireWildcard(obj) { if (obj && obj.__esModule) { return obj; } else { var newObj = {}; if (obj != null) { for (var key in obj) { if (Object.prototype.hasOwnProperty.call(obj, key)) newObj[key] = obj[key]; } } newObj.default = obj; return newObj; } }

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

const POSTCSS_CONFIG_PATH = require.resolve('./postcss.config');
const BABEL_PRESET_PATH = require.resolve('@kbn/babel-preset/webpack_preset');
const BABEL_EXCLUDE_RE = [/[\/\\](webpackShims|node_modules|bower_components)[\/\\]/];
const STATS_WARNINGS_FILTER = new RegExp(['(export .* was not found in)', '|(chunk .* \\[mini-css-extract-plugin\\]\\\nConflicting order between:)'].join(''));

class BaseOptimizer {
  constructor(opts) {
    this.logWithMetadata = opts.logWithMetadata || (() => null);
    this.uiBundles = opts.uiBundles;
    this.profile = opts.profile || false;

    switch (opts.sourceMaps) {
      case true:
        this.sourceMaps = 'source-map';
        break;

      case 'fast':
        this.sourceMaps = 'cheap-module-eval-source-map';
        break;

      default:
        this.sourceMaps = opts.sourceMaps || false;
        break;
    }

    // Run some pre loading in order to prevent
    // high delay when booting thread loader workers
    this.warmupThreadLoaderPool();
  }

  async init() {
    if (this.compiler) {
      return this;
    }

    const compilerConfig = this.getConfig();
    this.compiler = (0, _webpack2.default)(compilerConfig);

    // register the webpack compiler hooks
    // for the base optimizer
    this.registerCompilerHooks();

    return this;
  }

  registerCompilerHooks() {
    this.registerCompilerDoneHook();
  }

  registerCompilerDoneHook() {
    this.compiler.hooks.done.tap('base_optimizer-done', stats => {
      // We are not done while we have an additional
      // compilation pass to run
      // We also don't need to emit the stats if we don't have
      // the profile option set
      if (!this.profile || stats.compilation.needAdditionalPass) {
        return;
      }

      const path = this.uiBundles.resolvePath('stats.json');
      const content = JSON.stringify(stats.toJson());
      (0, _fs.writeFile)(path, content, function (err) {
        if (err) throw err;
      });
    });
  }

  warmupThreadLoaderPool() {
    const baseModules = ['babel-loader', BABEL_PRESET_PATH];

    const nonDistributableOnlyModules = !_utils.IS_KIBANA_DISTRIBUTABLE ? ['ts-loader'] : [];

    threadLoader.warmup(
    // pool options, like passed to loader options
    // must match loader options to boot the correct pool
    this.getThreadLoaderPoolConfig(), [
    // modules to load on the pool
    ...baseModules, ...nonDistributableOnlyModules]);
  }

  getThreadPoolCpuCount() {
    const cpus = _os2.default.cpus();
    if (!cpus) {
      // sometimes this call returns undefined so we fall back to 1: https://github.com/nodejs/node/issues/19022
      return 1;
    }

    return Math.max(1, Math.min(cpus.length - 1, 7));
  }

  getThreadLoaderPoolConfig() {
    // Calculate the node options from the NODE_OPTIONS env var
    const parsedNodeOptions = process.env.NODE_OPTIONS ? process.env.NODE_OPTIONS.split(/\s/) : [];

    return {
      name: 'optimizer-thread-loader-main-pool',
      workers: this.getThreadPoolCpuCount(),
      workerParallelJobs: 20,
      // This is a safe check in order to set
      // the parent node options applied from
      // the NODE_OPTIONS env var for every launched worker.
      // Otherwise, if the user sets max_old_space_size, as they
      // are used to, into NODE_OPTIONS, it won't affect the workers.
      workerNodeArgs: parsedNodeOptions,
      poolParallelJobs: this.getThreadPoolCpuCount() * 20,
      poolTimeout: this.uiBundles.isDevMode() ? Infinity : 2000
    };
  }

  getConfig() {
    function getStyleLoaderExtractor() {
      return [_miniCssExtractPlugin2.default.loader];
    }

    function getStyleLoaders(preProcessors = [], postProcessors = []) {
      return [...postProcessors, {
        loader: 'css-loader',
        options: {
          // importLoaders needs to know the number of loaders that follow this one,
          // so we add 1 (for the postcss-loader) to the length of the preProcessors
          // array that we merge into this array
          importLoaders: 1 + preProcessors.length
        }
      }, {
        loader: 'postcss-loader',
        options: {
          config: {
            path: POSTCSS_CONFIG_PATH
          }
        }
      }, ...preProcessors];
    }

    /**
     * Adds a cache loader if we're running in dev mode. The reason we're not adding
     * the cache-loader when running in production mode is that it creates cache
     * files in optimize/.cache that are not necessary for distributable versions
     * of Kibana and just make compressing and extracting it more difficult.
     */
    const maybeAddCacheLoader = (cacheName, loaders) => {
      if (_utils.IS_KIBANA_DISTRIBUTABLE) {
        return loaders;
      }

      return [{
        loader: 'cache-loader',
        options: {
          cacheDirectory: this.uiBundles.getCacheDirectory(cacheName)
        }
      }, ...loaders];
    };

    /**
     * Creates the selection rules for a loader that will only pass for
     * source files that are eligible for automatic transpilation.
     */
    const createSourceFileResourceSelector = test => {
      return [{
        test,
        exclude: BABEL_EXCLUDE_RE.concat(this.uiBundles.getWebpackNoParseRules())
      }, {
        test,
        include: /[\/\\]node_modules[\/\\]x-pack[\/\\]/,
        exclude: /[\/\\]node_modules[\/\\]x-pack[\/\\](.+?[\/\\])*node_modules[\/\\]/
      }];
    };

    const commonConfig = {
      mode: 'development',
      node: { fs: 'empty' },
      context: (0, _utils.fromRoot)('.'),
      cache: true,
      entry: this.uiBundles.toWebpackEntries(),

      devtool: this.sourceMaps,
      profile: this.profile || false,

      output: {
        path: this.uiBundles.getWorkingDir(),
        filename: '[name].bundle.js',
        sourceMapFilename: '[file].map',
        publicPath: _public_path_placeholder.PUBLIC_PATH_PLACEHOLDER,
        devtoolModuleFilenameTemplate: '[absolute-resource-path]'
      },

      optimization: {
        splitChunks: {
          cacheGroups: {
            commons: {
              name: 'commons',
              chunks: 'initial',
              minChunks: 2,
              reuseExistingChunk: true
            }
          }
        },
        noEmitOnErrors: true
      },

      plugins: [new _dynamic_dll_plugin.DynamicDllPlugin({
        uiBundles: this.uiBundles,
        threadLoaderPoolConfig: this.getThreadLoaderPoolConfig(),
        logWithMetadata: this.logWithMetadata
      }), new _miniCssExtractPlugin2.default({
        filename: '[name].style.css'
      }),

      // replace imports for `uiExports/*` modules with a synthetic module
      // created by create_ui_exports_module.js
      new _webpack2.default.NormalModuleReplacementPlugin(/^uiExports\//, resource => {
        // the map of uiExport types to module ids
        const extensions = this.uiBundles.getAppExtensions();

        // everything following the first / in the request is
        // treated as a type of appExtension
        const type = resource.request.slice(resource.request.indexOf('/') + 1);

        resource.request = [
        // the "val-loader" is used to execute create_ui_exports_module
        // and use its return value as the source for the module in the
        // bundle. This allows us to bypass writing to the file system
        require.resolve('val-loader'), '!', require.resolve('./create_ui_exports_module'), '?',
        // this JSON is parsed by create_ui_exports_module and determines
        // what require() calls it will execute within the bundle
        JSON.stringify({ type, modules: extensions[type] || [] })].join('');
      }), ...this.uiBundles.getWebpackPluginProviders().map(provider => provider(_webpack2.default))],

      module: {
        rules: [{
          test: /\.less$/,
          use: [...getStyleLoaderExtractor(), ...getStyleLoaders(['less-loader'], maybeAddCacheLoader('less', []))]
        }, {
          test: /\.css$/,
          use: [...getStyleLoaderExtractor(), ...getStyleLoaders([], maybeAddCacheLoader('css', []))]
        }, {
          test: /\.(html|tmpl)$/,
          loader: 'raw-loader'
        }, {
          test: /\.(png|jpg|gif|jpeg)$/,
          loader: ['url-loader']
        }, {
          test: /\.(woff|woff2|ttf|eot|svg|ico)(\?|$)/,
          loader: 'file-loader'
        }, {
          resource: createSourceFileResourceSelector(/\.js$/),
          use: maybeAddCacheLoader('babel', [{
            loader: 'thread-loader',
            options: this.getThreadLoaderPoolConfig()
          }, {
            loader: 'babel-loader',
            options: {
              babelrc: false,
              presets: [BABEL_PRESET_PATH]
            }
          }])
        }, ...this.uiBundles.getPostLoaders().map(loader => _extends({
          enforce: 'post'
        }, loader))],
        noParse: this.uiBundles.getWebpackNoParseRules()
      },

      resolve: {
        extensions: ['.js', '.json'],
        mainFields: ['browser', 'browserify', 'main'],
        modules: ['webpackShims', (0, _utils.fromRoot)('webpackShims'), 'node_modules', (0, _utils.fromRoot)('node_modules')],
        alias: this.uiBundles.getAliases()
      },

      performance: {
        // NOTE: we are disabling this as those hints
        // are more tailored for the final bundles result
        // and not for the webpack compilations performance itself
        hints: false
      }
    };

    // when running from the distributable define an environment variable we can use
    // to exclude chunks of code, modules, etc.
    const isDistributableConfig = {
      plugins: [new _webpack2.default.DefinePlugin({
        'process.env': {
          'IS_KIBANA_DISTRIBUTABLE': `"true"`
        }
      })]
    };

    // when running from source transpile TypeScript automatically
    const getSourceConfig = () => {
      // dev/typescript is deleted from the distributable, so only require it if we actually need the source config
      const { Project } = require('../dev/typescript');
      const browserProject = new Project((0, _utils.fromRoot)('tsconfig.browser.json'));

      return {
        module: {
          rules: [{
            resource: createSourceFileResourceSelector(/\.tsx?$/),
            use: maybeAddCacheLoader('typescript', [{
              loader: 'thread-loader',
              options: this.getThreadLoaderPoolConfig()
            }, {
              loader: 'ts-loader',
              options: {
                happyPackMode: true,
                transpileOnly: true,
                experimentalWatchApi: true,
                onlyCompileBundledFiles: true,
                configFile: (0, _utils.fromRoot)('tsconfig.json'),
                compilerOptions: _extends({}, browserProject.config.compilerOptions, {
                  sourceMap: Boolean(this.sourceMaps)
                })
              }
            }])
          }]
        },

        resolve: {
          extensions: ['.ts', '.tsx']
        }
      };
    };

    // We need to add react-addons (and a few other bits) for enzyme to work.
    // https://github.com/airbnb/enzyme/blob/master/docs/guides/webpack.md
    const supportEnzymeConfig = {
      externals: {
        'mocha': 'mocha',
        'react/lib/ExecutionEnvironment': true,
        'react/addons': true,
        'react/lib/ReactContext': true
      }
    };

    const watchingConfig = {
      plugins: [new _webpack2.default.WatchIgnorePlugin([
      // When our bundle entry files are fresh they cause webpack
      // to think they might have changed since the watcher was
      // initialized, which triggers a second compilation on startup.
      // Since we can't reliably update these files anyway, we can
      // just ignore them in the watcher and prevent the extra compilation
      /bundles[\/\\].+\.entry\.js/])]
    };

    // in production we set the process.env.NODE_ENV and run
    // the terser minimizer over our bundles
    const productionConfig = {
      mode: 'production',
      optimization: {
        minimizer: [new _terserWebpackPlugin2.default({
          parallel: true,
          sourceMap: false,
          terserOptions: {
            compress: false,
            mangle: false
          }
        })]
      }
    };

    return (0, _webpackMerge2.default)(commonConfig, _utils.IS_KIBANA_DISTRIBUTABLE ? isDistributableConfig : getSourceConfig(), this.uiBundles.isDevMode() ? (0, _webpackMerge2.default)(watchingConfig, supportEnzymeConfig) : productionConfig);
  }

  isFailure(stats) {
    if (stats.hasErrors()) {
      return true;
    }

    const { warnings } = stats.toJson({ all: false, warnings: true });

    // 1 - when typescript doesn't do a full type check, as we have the ts-loader
    // configured here, it does not have enough information to determine
    // whether an imported name is a type or not, so when the name is then
    // exported, typescript has no choice but to emit the export. Fortunately,
    // the extraneous export should not be harmful, so we just suppress these warnings
    // https://github.com/TypeStrong/ts-loader#transpileonly-boolean-defaultfalse
    //
    // 2 - Mini Css Extract plugin tracks the order for each css import we have
    // through the project (and it's successive imports) since version 0.4.2.
    // In case we have the same imports more than one time with different
    // sequences, this plugin will throw a warning. This should not be harmful,
    // but the an issue was opened and can be followed on:
    // https://github.com/webpack-contrib/mini-css-extract-plugin/issues/250#issuecomment-415345126
    const filteredWarnings = _Stats2.default.filterWarnings(warnings, STATS_WARNINGS_FILTER);

    return filteredWarnings.length > 0;
  }

  failedStatsToError(stats) {
    const details = stats.toString((0, _lodash.defaults)({ colors: true, warningsFilter: STATS_WARNINGS_FILTER }, _Stats2.default.presetToOptions('minimal')));

    return _boom2.default.internal(`Optimizations failure.\n${details.split('\n').join('\n    ')}\n`, stats.toJson((0, _lodash.defaults)(_extends({
      warningsFilter: STATS_WARNINGS_FILTER
    }, _Stats2.default.presetToOptions('detailed')))));
  }
}
exports.default = BaseOptimizer;
module.exports = exports['default'];