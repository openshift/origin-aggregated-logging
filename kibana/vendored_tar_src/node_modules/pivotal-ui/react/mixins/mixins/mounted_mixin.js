/*(c) Copyright 2015 Pivotal Software, Inc. All Rights Reserved.*/
"use strict";

exports.__esModule = true;

var _classCallCheck2 = require("babel-runtime/helpers/classCallCheck");

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _possibleConstructorReturn2 = require("babel-runtime/helpers/possibleConstructorReturn");

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = require("babel-runtime/helpers/inherits");

var _inherits3 = _interopRequireDefault(_inherits2);

var _weakMap = require("babel-runtime/core-js/weak-map");

var _weakMap2 = _interopRequireDefault(_weakMap);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var privates = new _weakMap2.default();

exports.default = function (ParentClass) {
  return function (_ParentClass) {
    (0, _inherits3.default)(Mounted, _ParentClass);

    function Mounted() {
      (0, _classCallCheck3.default)(this, Mounted);
      return (0, _possibleConstructorReturn3.default)(this, _ParentClass.apply(this, arguments));
    }

    Mounted.prototype.componentDidMount = function componentDidMount() {
      privates.set(this, { isMounted: true });
      if (_ParentClass.prototype.componentDidMount) _ParentClass.prototype.componentDidMount.call(this);
    };

    Mounted.prototype.componentWillUnmount = function componentWillUnmount() {
      privates.delete(this);
      if (_ParentClass.prototype.componentWillUnmount) _ParentClass.prototype.componentWillUnmount.call(this);
    };

    Mounted.prototype.mounted = function mounted() {
      var _ref = privates.get(this) || {},
          isMounted = _ref.isMounted;

      return !!isMounted;
    };

    return Mounted;
  }(ParentClass);
};

module.exports = exports["default"];