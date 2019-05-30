/*(c) Copyright 2015 Pivotal Software, Inc. All Rights Reserved.*/
'use strict';

exports.__esModule = true;
exports.ExpanderContent = exports.ExpanderTrigger = undefined;

var _extends2 = require('babel-runtime/helpers/extends');

var _extends3 = _interopRequireDefault(_extends2);

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

var _collapsible = require('../collapsible');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var ExpanderTrigger = exports.ExpanderTrigger = function (_React$PureComponent) {
  (0, _inherits3.default)(ExpanderTrigger, _React$PureComponent);

  function ExpanderTrigger(props, context) {
    (0, _classCallCheck3.default)(this, ExpanderTrigger);

    var _this = (0, _possibleConstructorReturn3.default)(this, _React$PureComponent.call(this, props, context));

    _this.setTarget = function (target) {
      return _this.setState({ target: target });
    };

    _this.toggleExpander = function (event) {
      event.preventDefault();
      if (_this.state.target) {
        _this.state.target.toggle();
      } else {
        console.warn('No ExpanderContent provided to ExpanderTrigger.');
      }
    };

    _this.state = {};
    return _this;
  }

  ExpanderTrigger.prototype.render = function render() {
    return _react2.default.cloneElement(this.props.children, { onClick: this.toggleExpander });
  };

  return ExpanderTrigger;
}(_react2.default.PureComponent);

var ExpanderContent = exports.ExpanderContent = function (_React$PureComponent2) {
  (0, _inherits3.default)(ExpanderContent, _React$PureComponent2);

  function ExpanderContent(props, context) {
    (0, _classCallCheck3.default)(this, ExpanderContent);

    var _this2 = (0, _possibleConstructorReturn3.default)(this, _React$PureComponent2.call(this, props, context));

    _this2.toggle = function () {
      return _this2.setState({ expanded: !_this2.state.expanded });
    };

    _this2.state = { expanded: _this2.props.expanded };
    return _this2;
  }

  ExpanderContent.prototype.componentWillReceiveProps = function componentWillReceiveProps(nextProps) {
    if (nextProps.expanded !== this.props.expanded) {
      this.setState({ expanded: nextProps.expanded });
    }
  };

  ExpanderContent.prototype.render = function render() {
    var expanded = this.state.expanded;

    return _react2.default.createElement(_collapsible.Collapsible, (0, _extends3.default)({}, this.props, { expanded: expanded }));
  };

  return ExpanderContent;
}(_react2.default.PureComponent);

ExpanderContent.propTypes = {
  expanded: _propTypes2.default.bool
};