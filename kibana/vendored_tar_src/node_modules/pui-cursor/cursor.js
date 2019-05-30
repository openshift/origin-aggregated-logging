//(c) Copyright 2015 Pivotal Software, Inc. All Rights Reserved.
'use strict';

exports.__esModule = true;

var _extends2 = require('babel-runtime/helpers/extends');

var _extends3 = _interopRequireDefault(_extends2);

var _promise = require('babel-runtime/core-js/promise');

var _promise2 = _interopRequireDefault(_promise);

var _entries = require('babel-runtime/core-js/object/entries');

var _entries2 = _interopRequireDefault(_entries);

var _classCallCheck2 = require('babel-runtime/helpers/classCallCheck');

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = require('babel-runtime/helpers/createClass');

var _createClass3 = _interopRequireDefault(_createClass2);

var _weakMap = require('babel-runtime/core-js/weak-map');

var _weakMap2 = _interopRequireDefault(_weakMap);

var _lodash = require('lodash.isobject');

var _lodash2 = _interopRequireDefault(_lodash);

var _lodash3 = require('lodash.flow');

var _lodash4 = _interopRequireDefault(_lodash3);

var _immutabilityHelper = require('immutability-helper');

var _immutabilityHelper2 = _interopRequireDefault(_immutabilityHelper);

var _warning = require('warning');

var _warning2 = _interopRequireDefault(_warning);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var async = true,
    debug = true;
var privates = new _weakMap2.default();

var Cursor = function () {
  (0, _createClass3.default)(Cursor, null, [{
    key: 'async',
    get: function get() {
      return async;
    },
    set: function set(bool) {
      async = bool;
    }
  }, {
    key: 'debug',
    get: function get() {
      return debug;
    },
    set: function set(bool) {
      debug = bool;
    }
  }]);

  function Cursor(data, callback) {
    var _ref = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : {},
        _ref$path = _ref.path,
        path = _ref$path === undefined ? [] : _ref$path,
        _ref$state = _ref.state,
        state = _ref$state === undefined ? { updates: [], data: data } : _ref$state;

    (0, _classCallCheck3.default)(this, Cursor);

    privates.set(this, { data: data, callback: callback, path: path, state: state });
  }

  Cursor.prototype.refine = function refine() {
    var _this = this;

    for (var _len = arguments.length, query = Array(_len), _key = 0; _key < _len; _key++) {
      query[_key] = arguments[_key];
    }

    var _privates$get = privates.get(this),
        callback = _privates$get.callback,
        data = _privates$get.data,
        path = _privates$get.path,
        state = _privates$get.state;

    query = query.reduce(function (memo, p) {
      return memo.push((0, _lodash2.default)(p) ? _this.get.apply(_this, memo).indexOf(p) : p), memo;
    }, []);
    return new Cursor(data, callback, { path: path.concat(query), state: state });
  };

  Cursor.prototype.get = function get() {
    var _privates$get2 = privates.get(this),
        data = _privates$get2.data,
        path = _privates$get2.path;

    for (var _len2 = arguments.length, morePath = Array(_len2), _key2 = 0; _key2 < _len2; _key2++) {
      morePath[_key2] = arguments[_key2];
    }

    return path.concat(morePath).reduce(function (memo, step) {
      return memo[step];
    }, data);
  };

  Cursor.prototype.isEqual = function isEqual(otherCursor) {
    return this.get() === otherCursor.get();
  };

  Cursor.prototype.apply = function apply(options) {
    return this.update({ $apply: options });
  };

  Cursor.prototype.merge = function merge(options) {
    return this.update({ $merge: options });
  };

  Cursor.prototype.set = function set(options) {
    return this.update({ $set: options });
  };

  Cursor.prototype.push = function push() {
    for (var _len3 = arguments.length, options = Array(_len3), _key3 = 0; _key3 < _len3; _key3++) {
      options[_key3] = arguments[_key3];
    }

    return this.update({ $push: options });
  };

  Cursor.prototype.remove = function remove(obj) {
    return this.apply(function (data) {
      if (Array.isArray(data)) return data.filter(function (i) {
        return i !== obj;
      });
      return (0, _entries2.default)(data).filter(function (_ref2) {
        var key = _ref2[0];
        return key !== obj.toString();
      }).reduce(function (memo, _ref3) {
        var key = _ref3[0],
            value = _ref3[1];
        return memo[key] = value, memo;
      }, {});
    });
  };

  Cursor.prototype.splice = function splice() {
    for (var _len4 = arguments.length, options = Array(_len4), _key4 = 0; _key4 < _len4; _key4++) {
      options[_key4] = arguments[_key4];
    }

    return this.update({ $splice: options });
  };

  Cursor.prototype.unshift = function unshift() {
    for (var _len5 = arguments.length, options = Array(_len5), _key5 = 0; _key5 < _len5; _key5++) {
      options[_key5] = arguments[_key5];
    }

    return this.update({ $unshift: options });
  };

  Cursor.prototype.nextTick = function nextTick(fn) {
    _promise2.default.resolve().then(fn).catch(function (error) {
      setTimeout(function () {
        throw error;
      }, 0);
    });
  };

  Cursor.prototype.flush = function flush() {
    var _privates$get3 = privates.get(this),
        callback = _privates$get3.callback,
        state = _privates$get3.state;

    if (!state.updates.length) return this;
    var fn = _lodash4.default.apply(undefined, state.updates);
    state.updates = [];
    state.data = fn.call(this, state.data);
    if (Cursor.async) state.stale = true;
    callback(state.data);
    return this;
  };

  Cursor.prototype.update = function update(options) {
    var _privates$get4 = privates.get(this),
        path = _privates$get4.path,
        _privates$get4$state = _privates$get4.state,
        updates = _privates$get4$state.updates,
        stale = _privates$get4$state.stale;

    if (Cursor.debug) (0, _warning2.default)(!stale, 'You are updating a stale cursor, this is almost always a bug');
    var query = path.reduceRight(function (memo, step) {
      var _ref4;

      return _ref4 = {}, _ref4[step] = (0, _extends3.default)({}, memo), _ref4;
    }, options);
    updates.push(function (data) {
      return (0, _immutabilityHelper2.default)(data, query);
    });
    if (!Cursor.async) return this.flush();
    if (updates.length === 1) this.nextTick(this.flush.bind(this));
    return this;
  };

  return Cursor;
}();

exports.default = Cursor;
module.exports = exports['default'];