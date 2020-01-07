/*(c) Copyright 2015 Pivotal Software, Inc. All Rights Reserved.*/
'use strict';

exports.__esModule = true;
exports.Pane = exports.BasePane = undefined;

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

var _helpers = require('../helpers');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var BasePane = exports.BasePane = function (_React$PureComponent) {
  (0, _inherits3.default)(BasePane, _React$PureComponent);

  function BasePane() {
    (0, _classCallCheck3.default)(this, BasePane);
    return (0, _possibleConstructorReturn3.default)(this, _React$PureComponent.apply(this, arguments));
  }

  BasePane.prototype.componentDidMount = function componentDidMount() {
    require('../../css/panes');
  };

  BasePane.prototype.render = function render() {
    var _props = this.props,
        innerClassName = _props.innerClassName,
        children = _props.children,
        other = (0, _objectWithoutProperties3.default)(_props, ['innerClassName', 'children']);

    var outerProps = (0, _helpers.mergeProps)(other, { className: 'pane' });
    var innerProps = (0, _helpers.mergeProps)({ className: innerClassName }, { className: 'container' });

    return _react2.default.createElement(
      'div',
      outerProps,
      _react2.default.createElement(
        'div',
        innerProps,
        children
      )
    );
  };

  return BasePane;
}(_react2.default.PureComponent);

BasePane.propTypes = {
  className: _propTypes2.default.string,
  innerClassName: _propTypes2.default.string
};

var Pane = exports.Pane = function (_React$PureComponent2) {
  (0, _inherits3.default)(Pane, _React$PureComponent2);

  function Pane() {
    (0, _classCallCheck3.default)(this, Pane);
    return (0, _possibleConstructorReturn3.default)(this, _React$PureComponent2.apply(this, arguments));
  }

  Pane.prototype.componentDidMount = function componentDidMount() {
    require('../../css/panes');
  };

  Pane.prototype.render = function render() {
    var _props2 = this.props,
        className = _props2.className,
        other = (0, _objectWithoutProperties3.default)(_props2, ['className']);

    return _react2.default.createElement(BasePane, (0, _extends3.default)({}, other, { className: className }));
  };

  return Pane;
}(_react2.default.PureComponent);

Pane.propTypes = {
  className: _propTypes2.default.string
};