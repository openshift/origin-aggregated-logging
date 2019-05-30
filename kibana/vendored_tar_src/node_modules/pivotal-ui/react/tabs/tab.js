/*(c) Copyright 2015 Pivotal Software, Inc. All Rights Reserved.*/
'use strict';

exports.__esModule = true;
exports.Tab = undefined;

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

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var Tab = exports.Tab = function (_React$PureComponent) {
  (0, _inherits3.default)(Tab, _React$PureComponent);

  function Tab() {
    (0, _classCallCheck3.default)(this, Tab);
    return (0, _possibleConstructorReturn3.default)(this, _React$PureComponent.apply(this, arguments));
  }

  Tab.prototype.render = function render() {
    return null;
  };

  return Tab;
}(_react2.default.PureComponent);

Tab.propTypes = {
  'aria-labelledby': _propTypes2.default.string,
  className: _propTypes2.default.string,
  disabled: _propTypes2.default.bool,
  eventKey: _propTypes2.default.any,
  onEntered: _propTypes2.default.func,
  onExited: _propTypes2.default.func,
  tabClassName: _propTypes2.default.string,
  title: _propTypes2.default.node.isRequired
};
Tab.defaultProps = {
  onEntered: function onEntered() {},
  onExited: function onExited() {}
};