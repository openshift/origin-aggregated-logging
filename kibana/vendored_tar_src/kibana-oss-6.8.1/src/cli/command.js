'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _lodash = require('lodash');

var _lodash2 = _interopRequireDefault(_lodash);

var _help = require('./help');

var _help2 = _interopRequireDefault(_help);

var _commander = require('commander');

var _color = require('./color');

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

_commander.Command.prototype.error = function (err) {
  if (err && err.message) err = err.message;

  console.log(`
${(0, _color.red)(' ERROR ')} ${err}

${(0, _help2.default)(this, '  ')}
`);

  process.exit(64); // eslint-disable-line no-process-exit
};

_commander.Command.prototype.defaultHelp = function () {
  console.log(`
${(0, _help2.default)(this, '  ')}

`);

  process.exit(64); // eslint-disable-line no-process-exit
};

_commander.Command.prototype.unknownArgv = function (argv) {
  if (argv) this.__unknownArgv = argv;
  return this.__unknownArgv ? this.__unknownArgv.slice(0) : [];
};

/**
 * setup the command to accept arbitrary configuration via the cli
 * @return {[type]} [description]
 */
_commander.Command.prototype.collectUnknownOptions = function () {
  const title = `Extra ${this._name} options`;

  this.allowUnknownOption();
  this.getUnknownOptions = function () {
    const opts = {};
    const unknowns = this.unknownArgv();

    while (unknowns.length) {
      const opt = unknowns.shift().split('=');
      if (opt[0].slice(0, 2) !== '--') {
        this.error(`${title} "${opt[0]}" must start with "--"`);
      }

      if (opt.length === 1) {
        if (!unknowns.length || unknowns[0][0] === '-') {
          this.error(`${title} "${opt[0]}" must have a value`);
        }

        opt.push(unknowns.shift());
      }

      let val = opt[1];
      try {
        val = JSON.parse(opt[1]);
      } catch (e) {
        val = opt[1];
      }

      _lodash2.default.set(opts, opt[0].slice(2), val);
    }

    return opts;
  };

  return this;
};

_commander.Command.prototype.parseOptions = _lodash2.default.wrap(_commander.Command.prototype.parseOptions, function (parse, argv) {
  const opts = parse.call(this, argv);
  this.unknownArgv(opts.unknown);
  return opts;
});

_commander.Command.prototype.action = _lodash2.default.wrap(_commander.Command.prototype.action, function (action, fn) {
  return action.call(this, function (...args) {
    const ret = fn.apply(this, args);
    if (ret && typeof ret.then === 'function') {
      ret.then(null, function (e) {
        console.log('FATAL CLI ERROR', e.stack);
        process.exit(1);
      });
    }
  });
});

exports.default = _commander.Command;
module.exports = exports['default'];