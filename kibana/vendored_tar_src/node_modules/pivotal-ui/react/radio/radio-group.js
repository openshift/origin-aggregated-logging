/*(c) Copyright 2015 Pivotal Software, Inc. All Rights Reserved.*/
'use strict';

exports.__esModule = true;
exports.RadioGroup = undefined;

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

var _classnames = require('classnames');

var _classnames2 = _interopRequireDefault(_classnames);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var RadioGroup = exports.RadioGroup = function (_React$Component) {
  (0, _inherits3.default)(RadioGroup, _React$Component);

  function RadioGroup() {
    (0, _classCallCheck3.default)(this, RadioGroup);
    return (0, _possibleConstructorReturn3.default)(this, _React$Component.apply(this, arguments));
  }

  RadioGroup.prototype.componentDidMount = function componentDidMount() {
    require('../../css/forms');
  };

  RadioGroup.prototype.render = function render() {
    var _props = this.props,
        name = _props.name,
        children = _props.children,
        onChange = _props.onChange,
        className = _props.className,
        others = (0, _objectWithoutProperties3.default)(_props, ['name', 'children', 'onChange', 'className']);

    var radioProps = onChange ? { name: name, onChange: onChange } : { name: name };

    var renderedChildren = _react2.default.Children.map(children, function (child) {
      return _react2.default.cloneElement(child, radioProps);
    });

    var props = (0, _extends3.default)({}, others, {
      className: (0, _classnames2.default)('pui-radio-group', className)
    });

    return _react2.default.createElement(
      'div',
      props,
      renderedChildren
    );
  };

  return RadioGroup;
}(_react2.default.Component);

RadioGroup.propTypes = {
  id: _propTypes2.default.string,
  name: _propTypes2.default.string.isRequired,
  onChange: _propTypes2.default.func
};