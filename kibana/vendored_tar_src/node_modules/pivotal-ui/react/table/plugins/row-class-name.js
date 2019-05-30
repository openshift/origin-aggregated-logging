/*(c) Copyright 2015 Pivotal Software, Inc. All Rights Reserved.*/
'use strict';

exports.__esModule = true;

var _objectWithoutProperties2 = require('babel-runtime/helpers/objectWithoutProperties');

var _objectWithoutProperties3 = _interopRequireDefault(_objectWithoutProperties2);

var _classCallCheck2 = require('babel-runtime/helpers/classCallCheck');

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _possibleConstructorReturn2 = require('babel-runtime/helpers/possibleConstructorReturn');

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = require('babel-runtime/helpers/inherits');

var _inherits3 = _interopRequireDefault(_inherits2);

exports.withRowClassName = withRowClassName;

var _react = require('react');

var _react2 = _interopRequireDefault(_react);

var _propTypes = require('prop-types');

var _propTypes2 = _interopRequireDefault(_propTypes);

var _tablePlugin = require('../table-plugin');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function withRowClassName(Table) {
  var _class, _temp;

  return _temp = _class = function (_TablePlugin) {
    (0, _inherits3.default)(TableWithRowClassName, _TablePlugin);

    function TableWithRowClassName() {
      (0, _classCallCheck3.default)(this, TableWithRowClassName);
      return (0, _possibleConstructorReturn3.default)(this, _TablePlugin.apply(this, arguments));
    }

    TableWithRowClassName.prototype.render = function render() {
      var _props = this.props,
          rowClassName = _props.rowClassName,
          props = (0, _objectWithoutProperties3.default)(_props, ['rowClassName']);

      return this.renderTable(Table, {
        tr: function tr(props, trContext) {
          return rowClassName && { className: rowClassName(trContext) };
        }
      }, props);
    };

    return TableWithRowClassName;
  }(_tablePlugin.TablePlugin), _class.propTypes = { rowClassName: _propTypes2.default.func }, _temp;
} // eslint-disable-next-line no-unused-vars