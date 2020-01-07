/*(c) Copyright 2015 Pivotal Software, Inc. All Rights Reserved.*/
'use strict';

exports.__esModule = true;

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

var TabHeaders = function (_React$Component) {
  (0, _inherits3.default)(TabHeaders, _React$Component);

  function TabHeaders() {
    (0, _classCallCheck3.default)(this, TabHeaders);
    return (0, _possibleConstructorReturn3.default)(this, _React$Component.apply(this, arguments));
  }

  TabHeaders.prototype.render = function render() {
    var _classnames;

    var _props = this.props,
        childArray = _props.childArray,
        activeKey = _props.activeKey,
        handleClick = _props.handleClick,
        isLeft = _props.isLeft,
        id = _props.id,
        onSelect = _props.onSelect,
        tabWidth = _props.tabWidth;

    var leftTabClasses = 'col-xs-' + tabWidth + ' nav-pills nav-stacked';

    var listChildren = childArray.map(function (child, key) {
      var _child$props = child.props,
          disabled = _child$props.disabled,
          eventKey = _child$props.eventKey,
          tabClassName = _child$props.tabClassName,
          title = _child$props.title;

      var paneId = id + '-pane-' + key;
      var tabId = id + '-tab-' + key;
      var isActive = eventKey === activeKey;

      var onClick = disabled ? function () {} : function (e) {
        return handleClick(e, eventKey, onSelect);
      };
      return _react2.default.createElement(
        'li',
        { key: key, role: 'presentation', className: (0, _classnames3.default)({ active: isActive, disabled: disabled }), 'aria-expanded': isActive },
        _react2.default.createElement(
          'a',
          { id: tabId, 'aria-controls': paneId, 'aria-selected': isActive, role: 'tab', className: tabClassName, tabIndex: '0',
            onClick: onClick },
          title
        )
      );
    });

    return _react2.default.createElement(
      'ul',
      { role: 'tablist', className: (0, _classnames3.default)('nav', { 'nav-tabs': !isLeft }, (_classnames = {}, _classnames[leftTabClasses] = isLeft, _classnames)) },
      listChildren
    );
  };

  return TabHeaders;
}(_react2.default.Component);

TabHeaders.propTypes = {
  activeKey: _propTypes2.default.any,
  childArray: _propTypes2.default.array,
  handleClick: _propTypes2.default.func,
  isLeft: _propTypes2.default.bool,
  id: _propTypes2.default.string.isRequired,
  onSelect: _propTypes2.default.func,
  tabWidth: _propTypes2.default.number
};
exports.default = TabHeaders;
module.exports = exports['default'];