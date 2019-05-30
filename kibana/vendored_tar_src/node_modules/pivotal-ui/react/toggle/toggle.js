/*(c) Copyright 2015 Pivotal Software, Inc. All Rights Reserved.*/
'use strict';

exports.__esModule = true;
exports.Toggle = undefined;

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

var _lodash = require('lodash.uniqueid');

var _lodash2 = _interopRequireDefault(_lodash);

var _classnames = require('classnames');

var _classnames2 = _interopRequireDefault(_classnames);

var _helpers = require('../helpers');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var Toggle = exports.Toggle = function (_React$PureComponent) {
  (0, _inherits3.default)(Toggle, _React$PureComponent);

  function Toggle() {
    (0, _classCallCheck3.default)(this, Toggle);
    return (0, _possibleConstructorReturn3.default)(this, _React$PureComponent.apply(this, arguments));
  }

  Toggle.prototype.componentDidMount = function componentDidMount() {
    require('../../css/forms');
  };

  Toggle.prototype.render = function render() {
    var _props = this.props,
        children = _props.children,
        id = _props.id,
        size = _props.size,
        className = _props.className,
        others = (0, _objectWithoutProperties3.default)(_props, ['children', 'id', 'size', 'className']);

    var toggleId = id || (0, _lodash2.default)('toggle');

    var inputProps = (0, _helpers.mergeProps)(others, {
      className: 'toggle-switch',
      id: toggleId,
      type: 'checkbox'
    });

    return _react2.default.createElement(
      'div',
      null,
      _react2.default.createElement('input', inputProps),
      _react2.default.createElement(
        'label',
        { htmlFor: toggleId, className: (0, _classnames2.default)(size, className) },
        children
      )
    );
  };

  return Toggle;
}(_react2.default.PureComponent);

Toggle.propTypes = {
  id: _propTypes2.default.string,
  size: _propTypes2.default.oneOf(['small', 'medium', 'large']),
  type: _propTypes2.default.oneOf(['checkbox'])
};
Toggle.defaultProps = {
  size: 'medium',
  type: 'checkbox'
};