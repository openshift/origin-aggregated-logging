/*(c) Copyright 2015 Pivotal Software, Inc. All Rights Reserved.*/
'use strict';

exports.__esModule = true;
exports.Collapsible = undefined;

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

var _react = require('react');

var _react2 = _interopRequireDefault(_react);

var _animation_mixin = require('../mixins/mixins/animation_mixin');

var _animation_mixin2 = _interopRequireDefault(_animation_mixin);

var _mixins = require('../mixins');

var _mixins2 = _interopRequireDefault(_mixins);

var _helpers = require('../helpers');

var _propTypes = require('prop-types');

var _propTypes2 = _interopRequireDefault(_propTypes);

var _bounding_client_rect = require('../mixins/components/bounding_client_rect');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var privates = new _weakMap2.default();

var CollapsibleComponent = function (_mixin$with) {
  (0, _inherits3.default)(CollapsibleComponent, _mixin$with);

  function CollapsibleComponent(props, context) {
    (0, _classCallCheck3.default)(this, CollapsibleComponent);

    var _this = (0, _possibleConstructorReturn3.default)(this, _mixin$with.call(this, props, context));

    _this.toggleAnimation = function (isAnimating) {
      return privates.set(_this, { isAnimating: isAnimating });
    };

    _this.triggerExpansionCallbacks = function (isAnimating) {
      if (isAnimating) return;
      var _this$props = _this.props,
          expanded = _this$props.expanded,
          onEntered = _this$props.onEntered,
          onExited = _this$props.onExited;

      expanded && onEntered && onEntered();
      !expanded && onExited && onExited();
      privates.set(_this, { expanded: expanded });
    };

    privates.set(_this, { isAnimating: false, expanded: props.expanded });
    return _this;
  }

  CollapsibleComponent.prototype.componentDidMount = function componentDidMount() {
    require('../../css/collapse');
  };

  CollapsibleComponent.prototype.render = function render() {
    var _props = this.props,
        _props$boundingClient = _props.boundingClientRect.height,
        height = _props$boundingClient === undefined ? 0 : _props$boundingClient,
        children = _props.children,
        container = _props.container,
        containerReady = _props.containerReady,
        delay = _props.delay,
        expanded = _props.expanded,
        onEntered = _props.onEntered,
        onExited = _props.onExited,
        others = (0, _objectWithoutProperties3.default)(_props, ['boundingClientRect', 'children', 'container', 'containerReady', 'delay', 'expanded', 'onEntered', 'onExited']);

    var fractionOpen = this.animate('fractionOpen', expanded ? 1 : 0, delay);
    var isAnimating = !expanded && fractionOpen > 0 || expanded && fractionOpen < 1;
    var style = height && isAnimating ? { marginBottom: -height * (1 - fractionOpen) } : {};

    if (privates.get(this).isAnimating !== isAnimating) {
      this.toggleAnimation(isAnimating);
    }

    if (privates.get(this).expanded !== expanded) {
      this.triggerExpansionCallbacks(isAnimating);
    }

    var props = (0, _helpers.mergeProps)(others, {
      className: ['collapse', { 'in': expanded || isAnimating }],
      style: isAnimating ? { overflow: 'hidden' } : {},
      'aria-hidden': !expanded
    });

    return _react2.default.createElement(
      'div',
      props,
      _react2.default.createElement(
        'div',
        { className: 'collapse-shield', style: style },
        children
      )
    );
  };

  return CollapsibleComponent;
}((0, _mixins2.default)(_react2.default.Component).with(_animation_mixin2.default));

CollapsibleComponent.propTypes = {
  boundingClientRect: _propTypes2.default.object,
  container: _propTypes2.default.object,
  containerReady: _propTypes2.default.object,
  delay: _propTypes2.default.number,
  disableAnimation: _propTypes2.default.bool,
  expanded: _propTypes2.default.bool,
  onEntered: _propTypes2.default.func,
  onExited: _propTypes2.default.func,
  transitionProgress: _propTypes2.default.number
};
CollapsibleComponent.defaultProps = {
  delay: 400
};
var Collapsible = exports.Collapsible = (0, _bounding_client_rect.useBoundingClientRect)(CollapsibleComponent);