/*(c) Copyright 2015 Pivotal Software, Inc. All Rights Reserved.*/
'use strict';

exports.__esModule = true;

var _classCallCheck2 = require('babel-runtime/helpers/classCallCheck');

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _possibleConstructorReturn2 = require('babel-runtime/helpers/possibleConstructorReturn');

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = require('babel-runtime/helpers/inherits');

var _inherits3 = _interopRequireDefault(_inherits2);

var _puiReactAnimation = require('pui-react-animation');

var _puiReactAnimation2 = _interopRequireDefault(_puiReactAnimation);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

exports.default = function (ParentClass) {
  return function (_ParentClass) {
    (0, _inherits3.default)(Animation, _ParentClass);

    function Animation() {
      var _temp, _this, _ret;

      (0, _classCallCheck3.default)(this, Animation);

      for (var _len = arguments.length, args = Array(_len), _key = 0; _key < _len; _key++) {
        args[_key] = arguments[_key];
      }

      return _ret = (_temp = (_this = (0, _possibleConstructorReturn3.default)(this, _ParentClass.call.apply(_ParentClass, [this].concat(args))), _this), _this.shouldAnimate = _puiReactAnimation2.default.shouldAnimate, _this.animate = _puiReactAnimation2.default.animate, _temp), (0, _possibleConstructorReturn3.default)(_this, _ret);
    }

    Animation.prototype.componentWillUnmount = function componentWillUnmount() {
      if (_ParentClass.prototype.componentWillUnmount) _ParentClass.prototype.componentWillUnmount.call(this);
      _puiReactAnimation2.default.componentWillUnmount.call(this);
    };

    return Animation;
  }(ParentClass);
};

module.exports = exports['default'];