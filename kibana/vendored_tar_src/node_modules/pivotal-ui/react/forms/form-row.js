/*(c) Copyright 2015 Pivotal Software, Inc. All Rights Reserved.*/
'use strict';

exports.__esModule = true;
exports.FormRow = undefined;

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

var _flexGrids = require('../flex-grids');

var _formCol = require('./form-col');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var FormRow = exports.FormRow = function (_React$Component) {
  (0, _inherits3.default)(FormRow, _React$Component);

  function FormRow() {
    (0, _classCallCheck3.default)(this, FormRow);
    return (0, _possibleConstructorReturn3.default)(this, _React$Component.apply(this, arguments));
  }

  FormRow.prototype.componentDidMount = function componentDidMount() {
    require('../../css/forms');
  };

  FormRow.prototype.render = function render() {
    var _props = this.props,
        wrapper = _props.wrapper,
        state = _props.state,
        children = _props.children,
        className = _props.className,
        id = _props.id,
        props = (0, _objectWithoutProperties3.default)(_props, ['wrapper', 'state', 'children', 'className', 'id']);


    var filteredChildren = _react2.default.Children.toArray(children).filter(function (child) {
      var childIsFormRow = child.type === _formCol.FormCol || child.type.prototype instanceof _formCol.FormCol;
      if (!childIsFormRow) {
        console.warn('Child of type "' + child.type + '" will not be rendered. A FormRow\'s children should be of type FormCol.');
      }
      return childIsFormRow;
    });

    var row = _react2.default.createElement(
      _flexGrids.Grid,
      { id: id, className: (0, _classnames2.default)(className, 'form-row') },
      _react2.default.Children.map(filteredChildren, function (formCol, key) {
        return _react2.default.cloneElement(formCol, (0, _extends3.default)({}, props, formCol.props, { state: state, key: key }));
      })
    );

    return wrapper ? _react2.default.cloneElement(wrapper(state), { children: row }) : row;
  };

  return FormRow;
}(_react2.default.Component);

FormRow.propTypes = {
  state: _propTypes2.default.object,
  setState: _propTypes2.default.func,
  canSubmit: _propTypes2.default.func,
  onSubmit: _propTypes2.default.func,
  canReset: _propTypes2.default.func,
  reset: _propTypes2.default.func,
  onChange: _propTypes2.default.func,
  onBlur: _propTypes2.default.func,
  onChangeCheckbox: _propTypes2.default.func,
  wrapper: _propTypes2.default.func
};