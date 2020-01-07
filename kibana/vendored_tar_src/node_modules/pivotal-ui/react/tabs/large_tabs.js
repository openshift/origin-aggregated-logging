/*(c) Copyright 2015 Pivotal Software, Inc. All Rights Reserved.*/
'use strict';

exports.__esModule = true;
exports.LargeTabs = undefined;

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

var _react = require('react');

var _react2 = _interopRequireDefault(_react);

var _propTypes = require('prop-types');

var _propTypes2 = _interopRequireDefault(_propTypes);

var _animation_mixin = require('../mixins/mixins/animation_mixin');

var _animation_mixin2 = _interopRequireDefault(_animation_mixin);

var _tab_content = require('./tab_content');

var _tab_content2 = _interopRequireDefault(_tab_content);

var _tab_headers = require('./tab_headers');

var _tab_headers2 = _interopRequireDefault(_tab_headers);

var _classnames = require('classnames');

var _classnames2 = _interopRequireDefault(_classnames);

var _mixins = require('../mixins');

var _mixins2 = _interopRequireDefault(_mixins);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var LargeTabs = exports.LargeTabs = function (_mixin$with) {
  (0, _inherits3.default)(LargeTabs, _mixin$with);

  function LargeTabs() {
    (0, _classCallCheck3.default)(this, LargeTabs);
    return (0, _possibleConstructorReturn3.default)(this, _mixin$with.apply(this, arguments));
  }

  LargeTabs.prototype.render = function render() {
    var _props = this.props,
        actions = _props.actions,
        activeKey = _props.activeKey,
        className = _props.className,
        childArray = _props.childArray,
        handleClick = _props.handleClick,
        id = _props.id,
        largeScreenClassName = _props.largeScreenClassName,
        onSelect = _props.onSelect,
        paneWidth = _props.paneWidth,
        position = _props.position,
        previousActiveKey = _props.previousActiveKey,
        tabType = _props.tabType,
        tabWidth = _props.tabWidth,
        transitionProgress = _props.transitionProgress,
        props = (0, _objectWithoutProperties3.default)(_props, ['actions', 'activeKey', 'className', 'childArray', 'handleClick', 'id', 'largeScreenClassName', 'onSelect', 'paneWidth', 'position', 'previousActiveKey', 'tabType', 'tabWidth', 'transitionProgress']);


    var currentActiveKey = transitionProgress >= 0.5 ? activeKey : previousActiveKey;
    var largeScreenClasses = (0, _classnames2.default)(['tab-' + tabType, largeScreenClassName, className]);
    var actionsNode = actions ? _react2.default.createElement(
      'div',
      { className: 'tabs-action' },
      actions
    ) : null;
    var isLeft = position === 'left';

    return _react2.default.createElement(
      'div',
      (0, _extends3.default)({ className: (0, _classnames2.default)(largeScreenClasses, { 'tab-left clearfix': isLeft }) }, props),
      actionsNode,
      _react2.default.createElement(_tab_headers2.default, { childArray: childArray, activeKey: activeKey, handleClick: handleClick, isLeft: isLeft, id: id, onSelect: onSelect, tabWidth: tabWidth }),
      _react2.default.createElement(_tab_content2.default, { childArray: childArray, activeKey: currentActiveKey, id: id, isLeft: isLeft, paneWidth: paneWidth, transitionProgress: transitionProgress })
    );
  };

  return LargeTabs;
}((0, _mixins2.default)(_react2.default.Component).with(_animation_mixin2.default));

LargeTabs.propTypes = {
  actions: _propTypes2.default.oneOfType([_propTypes2.default.node, _propTypes2.default.object]),
  activeKey: _propTypes2.default.any,
  childArray: _propTypes2.default.array,
  handleClick: _propTypes2.default.func,
  id: _propTypes2.default.string,
  largeScreenClassName: _propTypes2.default.string,
  onSelect: _propTypes2.default.func,
  paneWidth: _propTypes2.default.number,
  position: _propTypes2.default.oneOf(['top', 'left']),
  previouslyActiveKey: _propTypes2.default.any,
  tabType: _propTypes2.default.oneOf(['simple', 'simple-alt', 'left']),
  tabWidth: _propTypes2.default.number
};