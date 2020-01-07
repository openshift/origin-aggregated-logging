/*(c) Copyright 2015 Pivotal Software, Inc. All Rights Reserved.*/
'use strict';

exports.__esModule = true;
exports.BrandButton = exports.DangerButton = exports.PrimaryButton = exports.DefaultButton = exports.UIButton = undefined;

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

var UIButton = exports.UIButton = function (_React$Component) {
  (0, _inherits3.default)(UIButton, _React$Component);

  function UIButton() {
    (0, _classCallCheck3.default)(this, UIButton);
    return (0, _possibleConstructorReturn3.default)(this, _React$Component.apply(this, arguments));
  }

  UIButton.prototype.componentDidMount = function componentDidMount() {
    require('../../css/buttons');
  };

  UIButton.prototype.render = function render() {
    var _ref;

    var _props = this.props,
        alt = _props.alt,
        flat = _props.flat,
        icon = _props.icon,
        iconPosition = _props.iconPosition,
        iconOnly = _props.iconOnly,
        large = _props.large,
        small = _props.small,
        kind = _props.kind,
        children = _props.children,
        fullWidth = _props.fullWidth,
        others = (0, _objectWithoutProperties3.default)(_props, ['alt', 'flat', 'icon', 'iconPosition', 'iconOnly', 'large', 'small', 'kind', 'children', 'fullWidth']);


    var buttonClasses = {
      className: [(_ref = {
        'btn': true
      }, _ref['btn-' + kind + '-alt'] = alt, _ref['btn-' + kind + '-flat'] = flat, _ref['btn-' + kind] = !alt && !flat, _ref['btn-lg'] = large, _ref['btn-sm'] = small, _ref['btn-icon'] = iconOnly, _ref['btn-icon-right'] = !!icon && iconPosition === 'right', _ref['btn-full'] = fullWidth, _ref)]
    };
    var props = (0, _helpers.mergeProps)(others, buttonClasses);

    var buttonText = Array.isArray(children) ? children.filter(function (child) {
      return typeof child === 'string';
    }).join(' ') : typeof children === 'string' ? children.toString() : null;

    var btnChildren = children;

    if (buttonText && !iconOnly) {
      props = (0, _helpers.mergeProps)(props, { 'aria-label': buttonText });
      btnChildren = _react2.default.createElement(
        'span',
        null,
        children
      );
    }

    var buttonContent = _react2.default.createElement(
      'span',
      { className: 'btn-inner-content' },
      icon,
      btnChildren
    );

    if (iconPosition === 'right') {
      buttonContent = _react2.default.createElement(
        'span',
        { className: 'btn-inner-content' },
        btnChildren,
        icon
      );
    }

    return this.props.href ? _react2.default.createElement(
      'a',
      props,
      buttonContent
    ) : _react2.default.createElement(
      'button',
      (0, _helpers.mergeProps)(props, { type: 'button' }),
      buttonContent
    );
  };

  return UIButton;
}(_react2.default.Component);

UIButton.propTypes = {
  alt: _propTypes2.default.bool,
  flat: _propTypes2.default.bool,
  href: _propTypes2.default.string,
  icon: _propTypes2.default.oneOfType([_propTypes2.default.node, _propTypes2.default.object]),
  iconOnly: _propTypes2.default.bool,
  kind: _propTypes2.default.oneOf(['default', 'danger', 'primary', 'brand']),
  large: _propTypes2.default.bool,
  small: _propTypes2.default.bool,
  fullWidth: _propTypes2.default.bool,
  iconPosition: _propTypes2.default.oneOf(['left', 'right'])
};
UIButton.defaultProps = {
  kind: 'default',
  iconPosition: 'left'
};

var defButton = function defButton(propOverrides) {
  return function (_React$Component2) {
    (0, _inherits3.default)(_class, _React$Component2);

    function _class() {
      (0, _classCallCheck3.default)(this, _class);
      return (0, _possibleConstructorReturn3.default)(this, _React$Component2.apply(this, arguments));
    }

    _class.prototype.render = function render() {
      return _react2.default.createElement(UIButton, (0, _extends3.default)({}, this.props, propOverrides));
    };

    return _class;
  }(_react2.default.Component);
};

var DefaultButton = exports.DefaultButton = defButton();
var PrimaryButton = exports.PrimaryButton = defButton({ kind: 'primary' });
var DangerButton = exports.DangerButton = defButton({ kind: 'danger' });
var BrandButton = exports.BrandButton = defButton({ kind: 'brand' });