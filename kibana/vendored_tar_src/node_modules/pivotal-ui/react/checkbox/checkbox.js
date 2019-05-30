/*(c) Copyright 2015 Pivotal Software, Inc. All Rights Reserved.*/
'use strict';

exports.__esModule = true;
exports.Checkbox = undefined;

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

var _classnames = require('classnames');

var _classnames2 = _interopRequireDefault(_classnames);

var _iconography = require('../iconography');

var _propTypes = require('prop-types');

var _propTypes2 = _interopRequireDefault(_propTypes);

var _lodash = require('lodash.uniqueid');

var _lodash2 = _interopRequireDefault(_lodash);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var Checkbox = exports.Checkbox = function (_React$Component) {
  (0, _inherits3.default)(Checkbox, _React$Component);

  function Checkbox() {
    (0, _classCallCheck3.default)(this, Checkbox);
    return (0, _possibleConstructorReturn3.default)(this, _React$Component.apply(this, arguments));
  }

  Checkbox.prototype.componentDidMount = function componentDidMount() {
    require('../../css/forms');
    require('../../css/checkbox');
  };

  Checkbox.prototype.render = function render() {
    var _props = this.props,
        className = _props.className,
        disabled = _props.disabled,
        children = _props.children,
        labelClassName = _props.labelClassName,
        style = _props.style,
        _props$id = _props.id,
        id = _props$id === undefined ? (0, _lodash2.default)('checkbox') : _props$id,
        others = (0, _objectWithoutProperties3.default)(_props, ['className', 'disabled', 'children', 'labelClassName', 'style', 'id']);


    return _react2.default.createElement(
      'div',
      { className: (0, _classnames2.default)('pui-checkbox', className), style: style },
      _react2.default.createElement('input', (0, _extends3.default)({}, others, {
        className: 'pui-checkbox-input',
        type: 'checkbox',
        id: id,
        disabled: disabled,
        'aria-disabled': disabled
      })),
      _react2.default.createElement(
        'label',
        { className: (0, _classnames2.default)('pui-checkbox-label', labelClassName), htmlFor: id },
        _react2.default.createElement(
          'span',
          { className: 'pui-checkbox-control' },
          _react2.default.createElement(_iconography.Icon, { src: 'check' })
        ),
        children
      )
    );
  };

  return Checkbox;
}(_react2.default.Component);

Checkbox.propTypes = {
  checked: _propTypes2.default.bool,
  className: _propTypes2.default.string,
  disabled: _propTypes2.default.bool,
  defaultChecked: _propTypes2.default.bool,
  id: _propTypes2.default.string,
  labelClassName: _propTypes2.default.string,
  name: _propTypes2.default.string,
  onChange: _propTypes2.default.func,
  style: _propTypes2.default.object,
  type: _propTypes2.default.string.isRequired
};
Checkbox.defaultProps = {
  type: 'checkbox'
};