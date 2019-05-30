/*(c) Copyright 2015 Pivotal Software, Inc. All Rights Reserved.*/
'use strict';

exports.__esModule = true;

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

var _classnames2 = require('classnames');

var _classnames3 = _interopRequireDefault(_classnames2);

var _react = require('react');

var _react2 = _interopRequireDefault(_react);

var _propTypes = require('prop-types');

var _propTypes2 = _interopRequireDefault(_propTypes);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var TabContent = function (_React$Component) {
  (0, _inherits3.default)(TabContent, _React$Component);

  function TabContent() {
    (0, _classCallCheck3.default)(this, TabContent);
    return (0, _possibleConstructorReturn3.default)(this, _React$Component.apply(this, arguments));
  }

  TabContent.prototype.render = function render() {
    var _props = this.props,
        activeKey = _props.activeKey,
        childArray = _props.childArray,
        id = _props.id,
        isLeft = _props.isLeft,
        paneWidth = _props.paneWidth,
        transitionProgress = _props.transitionProgress;

    var tabContent = null;
    var leftPaneClasses = 'col-xs-' + paneWidth;

    childArray.forEach(function (child, key) {
      var _classnames;

      var _child$props = child.props,
          ariaLabelledBy = _child$props['aria-labelledby'],
          children = _child$props.children,
          className = _child$props.className,
          eventKey = _child$props.eventKey,
          onEntered = _child$props.onEntered,
          onExited = _child$props.onExited,
          tabClassName = _child$props.tabClassName,
          title = _child$props.title,
          props = (0, _objectWithoutProperties3.default)(_child$props, ['aria-labelledby', 'children', 'className', 'eventKey', 'onEntered', 'onExited', 'tabClassName', 'title']);


      var paneId = id + '-pane-' + key;
      var tabId = id + '-tab-' + key;
      var isActive = eventKey === activeKey;
      var style = transitionProgress < 1 ? { opacity: Math.abs(1 - 2 * transitionProgress) } : {};

      if (!isActive) return false;
      tabContent = _react2.default.createElement(
        'div',
        (0, _extends3.default)({ className: (0, _classnames3.default)('tab-content', (_classnames = {}, _classnames[leftPaneClasses] = isLeft, _classnames), className) }, props),
        _react2.default.createElement(
          'div',
          { className: 'tab-pane fade active in', id: paneId, role: 'tabpanel', 'aria-labelledby': ariaLabelledBy || tabId,
            'aria-hidden': 'false', style: style },
          children
        )
      );
    });

    return tabContent;
  };

  return TabContent;
}(_react2.default.Component);

TabContent.propTypes = {
  activeKey: _propTypes2.default.any,
  childArray: _propTypes2.default.array,
  id: _propTypes2.default.string,
  isLeft: _propTypes2.default.bool,
  paneWidth: _propTypes2.default.number,
  transitionProgress: _propTypes2.default.number
};
exports.default = TabContent;
module.exports = exports['default'];