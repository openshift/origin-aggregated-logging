/*(c) Copyright 2015 Pivotal Software, Inc. All Rights Reserved.*/
'use strict';

exports.__esModule = true;
exports.LeftTabs = exports.Tabs = undefined;

var _objectWithoutProperties2 = require('babel-runtime/helpers/objectWithoutProperties');

var _objectWithoutProperties3 = _interopRequireDefault(_objectWithoutProperties2);

var _extends2 = require('babel-runtime/helpers/extends');

var _extends3 = _interopRequireDefault(_extends2);

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

var _large_tabs = require('./large_tabs');

var _mixins = require('../mixins');

var _mixins2 = _interopRequireDefault(_mixins);

var _propTypes = require('prop-types');

var _propTypes2 = _interopRequireDefault(_propTypes);

var _mediaSize = require('./media-size');

var _small_tabs = require('./small_tabs');

var _lodash = require('lodash.uniqueid');

var _lodash2 = _interopRequireDefault(_lodash);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var privates = new _weakMap2.default();

var triggerEnteredAndExitedCallbacks = function triggerEnteredAndExitedCallbacks(childArray, _ref) {
  var enteredKey = _ref.enteredKey,
      exitedKey = _ref.exitedKey;

  childArray.forEach(function (_ref2) {
    var _ref2$props = _ref2.props,
        eventKey = _ref2$props.eventKey,
        onEntered = _ref2$props.onEntered,
        onExited = _ref2$props.onExited;

    if (eventKey === enteredKey) {
      onEntered(eventKey);
    } else if (eventKey === exitedKey) {
      onExited(eventKey);
    }
  });
};

var Tabs = exports.Tabs = function (_mixin$with) {
  (0, _inherits3.default)(Tabs, _mixin$with);

  function Tabs(props, context) {
    (0, _classCallCheck3.default)(this, Tabs);

    var _this = (0, _possibleConstructorReturn3.default)(this, _mixin$with.call(this, props, context));

    _this.setActiveKey = function (key) {
      var previousActiveKey = _this.state.activeKey;
      _this.setState({
        activeKey: key,
        previousActiveKey: previousActiveKey
      });

      if (key !== previousActiveKey) {
        _this.animate('transitionProgress', 0);
        privates.set(_this, 0);
      }
    };

    _this.checkScreenSize = function () {
      if ((0, _mediaSize.matches)(_this.props.responsiveBreakpoint)) {
        _this.setState({ smallScreen: false });
      } else {
        _this.setState({ smallScreen: true });
      }
    };

    _this.updateTransitionProgressAndTriggerCallbacks = function (childArray) {
      var animation = _this.props.animation;

      var oldTransitionProgress = privates.get(_this);
      var transitionProgress = _this.animate('transitionProgress', 1, animation ? Tabs.ANIMATION_TIME : 0);
      _this.triggerTransitionCallbacks({ childArray: childArray, oldTransitionProgress: oldTransitionProgress, transitionProgress: transitionProgress });

      privates.set(_this, transitionProgress);
      return transitionProgress;
    };

    _this.triggerTransitionCallbacks = function (_ref3) {
      var childArray = _ref3.childArray,
          oldTransitionProgress = _ref3.oldTransitionProgress,
          transitionProgress = _ref3.transitionProgress;

      if (oldTransitionProgress < 1 && transitionProgress === 1) {
        var exitedKey = _this.state.previousActiveKey;
        var enteredKey = _this.state.activeKey;
        triggerEnteredAndExitedCallbacks(childArray, { enteredKey: enteredKey, exitedKey: exitedKey });
      }
    };

    _this.handleClick = function (e, eventKey, callback) {
      if (callback) {
        callback(e, eventKey);
      } else {
        _this.setActiveKey(eventKey);
      }
    };

    var id = _this.props.id;

    if (typeof id === 'undefined') {
      id = (0, _lodash2.default)('pui-react-tabs-');
    }
    _this.state = {
      activeKey: _this.props.defaultActiveKey,
      smallScreen: false,
      id: id
    };
    privates.set(_this, 0);
    return _this;
  }

  Tabs.prototype.componentDidMount = function componentDidMount() {
    require('../../css/tabs');
  };

  Tabs.prototype.componentWillReceiveProps = function componentWillReceiveProps(nextProps) {
    if (nextProps.defaultActiveKey !== this.props.defaultActiveKey) {
      this.setActiveKey(nextProps.defaultActiveKey);
    }
  };

  Tabs.prototype.componentDidMount = function componentDidMount() {
    window.addEventListener('resize', this.checkScreenSize);
    this.checkScreenSize();
  };

  Tabs.prototype.componentWillUnmount = function componentWillUnmount() {
    window.removeEventListener('resize', this.checkScreenSize);
  };

  Tabs.prototype.render = function render() {
    var children = this.props.children;

    var childArray = _react2.default.Children.toArray(children);
    var transitionProgress = this.updateTransitionProgressAndTriggerCallbacks(childArray);

    if (this.state.smallScreen) {
      return _react2.default.createElement(_small_tabs.SmallTabs, (0, _extends3.default)({}, this.state, this.props, {
        transitionProgress: transitionProgress,
        handleClick: this.handleClick
      }));
    }

    var _props = this.props,
        __ignore1 = _props.animation,
        _ignore2 = _props.children,
        __ignore3 = _props.defaultActiveKey,
        _props$id = _props.id,
        id = _props$id === undefined ? this.state.id : _props$id,
        __ignore4 = _props.responsiveBreakpoint,
        __ignore5 = _props.smallScreenClassName,
        props = (0, _objectWithoutProperties3.default)(_props, ['animation', 'children', 'defaultActiveKey', 'id', 'responsiveBreakpoint', 'smallScreenClassName']);
    var _state = this.state,
        activeKey = _state.activeKey,
        previousActiveKey = _state.previousActiveKey;


    return _react2.default.createElement(_large_tabs.LargeTabs, (0, _extends3.default)({}, props, { childArray: childArray, activeKey: activeKey, previousActiveKey: previousActiveKey, id: id, handleClick: this.handleClick, transitionProgress: transitionProgress }));
  };

  return Tabs;
}((0, _mixins2.default)(_react2.default.Component).with(_animation_mixin2.default));

Tabs.propTypes = {
  actions: _propTypes2.default.oneOfType([_propTypes2.default.node, _propTypes2.default.object]),
  activeKey: _propTypes2.default.number,
  animation: _propTypes2.default.bool,
  defaultActiveKey: _propTypes2.default.any,
  id: _propTypes2.default.string,
  largeScreenClassName: _propTypes2.default.string,
  onSelect: _propTypes2.default.func,
  paneWidth: _propTypes2.default.number,
  position: _propTypes2.default.oneOf(['top', 'left']),
  responsiveBreakpoint: _propTypes2.default.oneOf(['xs', 'sm', 'md', 'lg']),
  smallScreenClassName: _propTypes2.default.string,
  tabType: _propTypes2.default.oneOf(['simple', 'simple-alt', 'left']),
  tabWidth: _propTypes2.default.number
};
Tabs.defaultProps = {
  animation: true,
  responsiveBreakpoint: 'xs',
  tabType: 'simple'
};
Tabs.ANIMATION_TIME = 400;

var LeftTabs = exports.LeftTabs = function (_React$PureComponent) {
  (0, _inherits3.default)(LeftTabs, _React$PureComponent);

  function LeftTabs() {
    (0, _classCallCheck3.default)(this, LeftTabs);
    return (0, _possibleConstructorReturn3.default)(this, _React$PureComponent.apply(this, arguments));
  }

  LeftTabs.prototype.componentDidMount = function componentDidMount() {
    require('../../css/tabs');
  };

  LeftTabs.prototype.render = function render() {
    var _props2 = this.props,
        tabWidth = _props2.tabWidth,
        paneWidth = _props2.paneWidth,
        props = (0, _objectWithoutProperties3.default)(_props2, ['tabWidth', 'paneWidth']);

    if (!paneWidth) {
      paneWidth = 24 - tabWidth;
    }
    return _react2.default.createElement(Tabs, (0, _extends3.default)({}, props, { tabWidth: tabWidth, paneWidth: paneWidth }));
  };

  return LeftTabs;
}(_react2.default.PureComponent);

LeftTabs.propTypes = {
  position: _propTypes2.default.oneOf(['top', 'left']),
  tabWidth: _propTypes2.default.number,
  paneWidth: _propTypes2.default.number
};
LeftTabs.defaultProps = {
  position: 'left',
  tabWidth: 6,
  tabType: 'left'
};