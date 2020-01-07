/*(c) Copyright 2015 Pivotal Software, Inc. All Rights Reserved.*/
'use strict';

exports.__esModule = true;
exports.BackToTop = undefined;

var _extends2 = require('babel-runtime/helpers/extends');

var _extends3 = _interopRequireDefault(_extends2);

var _objectWithoutProperties2 = require('babel-runtime/helpers/objectWithoutProperties');

var _objectWithoutProperties3 = _interopRequireDefault(_objectWithoutProperties2);

var _classCallCheck2 = require('babel-runtime/helpers/classCallCheck');

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _possibleConstructorReturn2 = require('babel-runtime/helpers/possibleConstructorReturn');

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = require('babel-runtime/helpers/inherits');

var _inherits3 = _interopRequireDefault(_inherits2);

var _weakMap = require('babel-runtime/core-js/weak-map');

var _weakMap2 = _interopRequireDefault(_weakMap);

var _iconography = require('../iconography');

var _react = require('react');

var _react2 = _interopRequireDefault(_react);

var _propTypes = require('prop-types');

var _propTypes2 = _interopRequireDefault(_propTypes);

var _lodash = require('lodash.throttle');

var _lodash2 = _interopRequireDefault(_lodash);

var _scrollTop = require('./scroll-top');

var _scrollTop2 = _interopRequireDefault(_scrollTop);

var _helpers = require('../helpers');

var _mixins = require('../mixins');

var _mixins2 = _interopRequireDefault(_mixins);

var _animation_mixin = require('../mixins/mixins/animation_mixin');

var _animation_mixin2 = _interopRequireDefault(_animation_mixin);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var isFirefox = function isFirefox() {
  return navigator.userAgent.toLowerCase().indexOf('firefox') !== -1;
};

function getElement(id) {
  if (id) return document.getElementById(id);
  if (isFirefox()) return document.documentElement;
  return document.body;
}

var privates = new _weakMap2.default();

var BackToTop = exports.BackToTop = function (_mixin$with) {
  (0, _inherits3.default)(BackToTop, _mixin$with);

  function BackToTop(props, context) {
    (0, _classCallCheck3.default)(this, BackToTop);

    var _this = (0, _possibleConstructorReturn3.default)(this, _mixin$with.call(this, props, context));

    _this.updateScroll = function () {
      var _privates$get = privates.get(_this),
          element = _privates$get.element;

      _this.setState({ visible: _scrollTop2.default.getScrollTop(element) > BackToTop.VISIBILITY_HEIGHT });
    };

    _this.scrollToTop = function () {
      var key = 'pui-back-to-top-' + Date.now();
      _this.setState({ key: key });
    };

    _this.state = { visible: false };
    return _this;
  }

  BackToTop.prototype.componentDidMount = function componentDidMount() {
    require('../../css/back-to-top');
    this.updateScroll = (0, _lodash2.default)(this.updateScroll, 100);
    window.addEventListener('scroll', this.updateScroll);
    var scrollableId = this.props.scrollableId;

    var element = getElement(scrollableId);
    privates.set(this, { element: element });
  };

  BackToTop.prototype.componentWillUnmount = function componentWillUnmount() {
    window.removeEventListener('scroll', this.updateScroll);
  };

  BackToTop.prototype.render = function render() {
    var _this2 = this;

    var _props = this.props,
        alwaysVisible = _props.alwaysVisible,
        scrollableId = _props.scrollableId,
        others = (0, _objectWithoutProperties3.default)(_props, ['alwaysVisible', 'scrollableId']);
    var visibleState = this.state.visible;

    var _ref = privates.get(this) || {},
        element = _ref.element;

    var visible = alwaysVisible || visibleState;
    var props = (0, _helpers.mergeProps)(others, {
      className: 'back-to-top',
      style: { display: 'inline', opacity: this.animate('opacity', visible ? 1 : 0, BackToTop.FADE_DURATION) }
    });

    var key = this.state.key;

    if (key) {
      var startValue = _scrollTop2.default.getScrollTop(element);
      var scrollTarget = this.animate(key, 0, BackToTop.SCROLL_DURATION, {
        startValue: startValue,
        easing: 'easeOutCubic'
      });
      _scrollTop2.default.setScrollTop(scrollTarget, element);
      if (!scrollTarget) setTimeout(function () {
        return _this2.setState({ key: null });
      }, 10);
    }

    return _react2.default.createElement(
      'a',
      (0, _extends3.default)({}, props, { onClick: this.scrollToTop, 'aria-label': 'Back to top' }),
      _react2.default.createElement(_iconography.Icon, { style: { strokeWidth: 100 }, src: 'arrow_upward' })
    );
  };

  return BackToTop;
}((0, _mixins2.default)(_react2.default.PureComponent).with(_animation_mixin2.default));

BackToTop.propTypes = {
  alwaysVisible: _propTypes2.default.bool,
  scrollableId: _propTypes2.default.string
};
BackToTop.FADE_DURATION = 300;
BackToTop.VISIBILITY_HEIGHT = 400;
BackToTop.SCROLL_DURATION = 200;