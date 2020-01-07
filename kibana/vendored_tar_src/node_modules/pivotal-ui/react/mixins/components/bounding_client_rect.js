/*(c) Copyright 2015 Pivotal Software, Inc. All Rights Reserved.*/
'use strict';

exports.__esModule = true;
exports.useBoundingClientRect = undefined;

var _setImmediate2 = require('babel-runtime/core-js/set-immediate');

var _setImmediate3 = _interopRequireDefault(_setImmediate2);

var _extends2 = require('babel-runtime/helpers/extends');

var _extends3 = _interopRequireDefault(_extends2);

var _promise = require('babel-runtime/core-js/promise');

var _promise2 = _interopRequireDefault(_promise);

var _classCallCheck2 = require('babel-runtime/helpers/classCallCheck');

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _possibleConstructorReturn2 = require('babel-runtime/helpers/possibleConstructorReturn');

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = require('babel-runtime/helpers/inherits');

var _inherits3 = _interopRequireDefault(_inherits2);

var _weakMap = require('babel-runtime/core-js/weak-map');

var _weakMap2 = _interopRequireDefault(_weakMap);

var _raf = require('raf');

var _raf2 = _interopRequireDefault(_raf);

var _react = require('react');

var _react2 = _interopRequireDefault(_react);

var _reactDom = require('react-dom');

var _reactDom2 = _interopRequireDefault(_reactDom);

var _shallowEqual = require('fbjs/lib/shallowEqual');

var _shallowEqual2 = _interopRequireDefault(_shallowEqual);

var _mixins = require('../mixins');

var _mixins2 = _interopRequireDefault(_mixins);

var _mounted_mixin = require('../mixins/mounted_mixin');

var _mounted_mixin2 = _interopRequireDefault(_mounted_mixin);

var _shallow_compare_mixin = require('../mixins/shallow_compare_mixin');

var _shallow_compare_mixin2 = _interopRequireDefault(_shallow_compare_mixin);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var Component = (0, _mixins2.default)(_react2.default.Component).with(_shallow_compare_mixin2.default);
var rafify = function rafify(callback) {
  return function () {
    for (var _len = arguments.length, args = Array(_len), _key = 0; _key < _len; _key++) {
      args[_key] = arguments[_key];
    }

    return (0, _raf2.default)(function () {
      return callback.call.apply(callback, [undefined].concat(args));
    });
  };
};
var privates = new _weakMap2.default();
var properties = ['width', 'height', 'top', 'right', 'bottom', 'left'];

var useBoundingClientRect = exports.useBoundingClientRect = function useBoundingClientRect(Klass) {
  return function (_mixin$with) {
    (0, _inherits3.default)(BoundingClientRect, _mixin$with);

    function BoundingClientRect(props, context) {
      (0, _classCallCheck3.default)(this, BoundingClientRect);

      var _this = (0, _possibleConstructorReturn3.default)(this, _mixin$with.call(this, props, context));

      _this.resize = function () {
        var _ref = privates.get(_this) || {},
            prevBoundingClientRect = _ref.boundingClientRect;

        var boundingClientRect = _this.getBoundingClientRect();
        var isNotEqual = function isNotEqual(property) {
          return boundingClientRect[property] !== prevBoundingClientRect[property];
        };
        if (!prevBoundingClientRect || properties.some(isNotEqual)) {
          _this.mounted() && _this.forceUpdate();
        }
      };

      var resolver = void 0;
      var containerReady = new _promise2.default(function (resolve) {
        return resolver = resolve;
      });
      containerReady.resolve = resolver;
      var state = _this.state;

      _this.state = (0, _extends3.default)({}, state, { container: null, containerReady: containerReady });
      _this.resize = rafify(_this.resize);

      _this.getBoundingClientRect = _this.getBoundingClientRect.bind(_this);
      return _this;
    }

    BoundingClientRect.prototype.componentDidMount = function componentDidMount() {
      var _this2 = this;

      _mixin$with.prototype.componentDidMount.call(this);
      privates.set(this, { resize: this.resize });
      window.addEventListener('resize', this.resize);
      this.setState({ container: _reactDom2.default.findDOMNode(this.component) });
      (0, _setImmediate3.default)(function () {
        return _this2.state.containerReady.resolve(_this2.state.container);
      });
    };

    BoundingClientRect.prototype.componentWillUnmount = function componentWillUnmount() {
      _mixin$with.prototype.componentWillUnmount.call(this);

      var _ref2 = privates.get(this) || {},
          resize = _ref2.resize;

      window.removeEventListener('resize', resize);
      privates.delete(this);
    };

    BoundingClientRect.prototype.componentWillReceiveProps = function componentWillReceiveProps(nextProps) {
      if (!(0, _shallowEqual2.default)(this.props, nextProps)) this.resize();
    };

    BoundingClientRect.prototype.getBoundingClientRect = function getBoundingClientRect() {
      return this.state.container && this.state.container.getBoundingClientRect() || {};
    };

    BoundingClientRect.prototype.render = function render() {
      var _this3 = this;

      var _ref3 = privates.get(this) || {},
          resize = _ref3.resize;

      var boundingClientRect = this.getBoundingClientRect();
      privates.set(this, { boundingClientRect: boundingClientRect, resize: resize });
      return _react2.default.createElement(Klass, (0, _extends3.default)({}, this.props, this.state, { boundingClientRect: boundingClientRect }, { ref: function ref(_ref4) {
          return _this3.component = _ref4;
        } }));
    };

    return BoundingClientRect;
  }((0, _mixins2.default)(Component).with(_mounted_mixin2.default));
};