//(c) Copyright 2015 Pivotal Software, Inc. All Rights Reserved.
'use strict';

exports.__esModule = true;

var _assign = require('babel-runtime/core-js/object/assign');

var _assign2 = _interopRequireDefault(_assign);

var _values = require('babel-runtime/core-js/object/values');

var _values2 = _interopRequireDefault(_values);

var _isNan = require('babel-runtime/core-js/number/is-nan');

var _isNan2 = _interopRequireDefault(_isNan);

var _weakMap = require('babel-runtime/core-js/weak-map');

var _weakMap2 = _interopRequireDefault(_weakMap);

exports.default = injector;

var _easingJs = require('easing-js');

var injectedEasing = _interopRequireWildcard(_easingJs);

var _performanceNow = require('performance-now');

var _performanceNow2 = _interopRequireDefault(_performanceNow);

var _raf = require('raf');

var _raf2 = _interopRequireDefault(_raf);

function _interopRequireWildcard(obj) { if (obj && obj.__esModule) { return obj; } else { var newObj = {}; if (obj != null) { for (var key in obj) { if (Object.prototype.hasOwnProperty.call(obj, key)) newObj[key] = obj[key]; } } newObj.default = obj; return newObj; } }

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var privates = new _weakMap2.default();

function isNumber(obj) {
  return typeof obj === 'number' && !(0, _isNan2.default)(obj);
}

function strip(number) {
  return parseFloat(number.toPrecision(12));
}

function someAnimating(animations) {
  return (0, _values2.default)(animations).some(function (animation) {
    return animation.isAnimating;
  });
}

function reset() {
  privates.delete(this);
}

function injector() {
  var _ref = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : {},
      _ref$raf = _ref.raf,
      raf = _ref$raf === undefined ? _raf2.default : _ref$raf,
      _ref$now = _ref.now,
      now = _ref$now === undefined ? _performanceNow2.default : _ref$now,
      _ref$Easing = _ref.Easing,
      Easing = _ref$Easing === undefined ? injectedEasing : _ref$Easing;

  function getEasing(easing) {
    return typeof easing === 'function' ? easing : Easing[easing];
  }

  function scheduleAnimation(context) {
    raf(function () {
      var animations = privates.get(context);
      if (!animations) return;
      var currentTime = now();
      var shouldForceUpdate = (0, _values2.default)(animations).reduce(function (shouldForceUpdate, animation) {
        if (!animation.isAnimating) return shouldForceUpdate;

        var duration = animation.duration,
            easing = animation.easing,
            endValue = animation.endValue,
            startTime = animation.startTime,
            startValue = animation.startValue,
            nameFn = animation.nameFn;


        var deltaTime = currentTime - startTime;
        if (deltaTime >= duration) {
          (0, _assign2.default)(animation, { isAnimating: false, startTime: currentTime, value: endValue });
        } else {
          animation.value = strip(easing(deltaTime, startValue, endValue - startValue, duration));
        }

        if (nameFn) nameFn(animation.value);
        return shouldForceUpdate || !nameFn;
      }, false);

      if (animations && someAnimating(animations)) scheduleAnimation(context);
      if (shouldForceUpdate) context.forceUpdate();
    });
  }

  return (0, _assign2.default)(function animate(name, endValue, duration) {
    var options = arguments.length > 3 && arguments[3] !== undefined ? arguments[3] : {};

    var animations = privates.get(this);
    if (!animations) privates.set(this, animations = {});

    var animation = animations[name];
    var shouldAnimate = (this.shouldAnimate ? this.shouldAnimate() : true) && options.animation !== false;

    if (!animation || !shouldAnimate || !isNumber(endValue)) {
      var easing = getEasing(options.easing || 'linear');
      var startValue = isNumber(options.startValue) && shouldAnimate ? options.startValue : endValue;
      var nameFn = typeof name === 'function' && name;
      animation = { duration: duration, easing: easing, endValue: endValue, isAnimating: false, startValue: startValue, value: startValue, nameFn: nameFn };
      animations[name] = animation;
    }

    if (!duration) {
      (0, _assign2.default)(animation, { endValue: endValue, value: endValue });
      animations[name] = animation;
    }

    if (animation.value !== endValue && !animation.isAnimating) {
      if (!someAnimating(animations)) scheduleAnimation(this);
      var startTime = 'startTime' in options ? options.startTime : now();
      duration = duration || animation.duration;
      var _easing = getEasing(options.easing || animation.easing);
      var _startValue = animation.value;
      var _nameFn = typeof name === 'function' && name;
      (0, _assign2.default)(animation, { isAnimating: true, endValue: endValue, startValue: _startValue, startTime: startTime, duration: duration, easing: _easing, nameFn: _nameFn });
    }

    return animation.value;
  }, { reset: reset });
}
module.exports = exports['default'];