/*(c) Copyright 2015 Pivotal Software, Inc. All Rights Reserved.*/
'use strict';

exports.__esModule = true;

var _classCallCheck2 = require('babel-runtime/helpers/classCallCheck');

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _possibleConstructorReturn2 = require('babel-runtime/helpers/possibleConstructorReturn');

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = require('babel-runtime/helpers/inherits');

var _inherits3 = _interopRequireDefault(_inherits2);

var _typeof2 = require('babel-runtime/helpers/typeof');

var _typeof3 = _interopRequireDefault(_typeof2);

exports.withCellClassName = withCellClassName;

var _react = require('react');

var _react2 = _interopRequireDefault(_react);

var _tablePlugin = require('../table-plugin');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

// eslint-disable-next-line no-unused-vars
function withCellClassName(Table) {
  var cellClassName = function cellClassName(className, rowDatum, isHeader) {
    switch (typeof className === 'undefined' ? 'undefined' : (0, _typeof3.default)(className)) {
      case 'string':
        return { className: className };
      case 'function':
        return { className: className(rowDatum, isHeader) };
      default:
        return;
    }
  };

  return function (_TablePlugin) {
    (0, _inherits3.default)(TableWithCellClassName, _TablePlugin);

    function TableWithCellClassName() {
      (0, _classCallCheck3.default)(this, TableWithCellClassName);
      return (0, _possibleConstructorReturn3.default)(this, _TablePlugin.apply(this, arguments));
    }

    TableWithCellClassName.prototype.render = function render() {
      return this.renderTable(Table, {
        th: function th(props, _ref) {
          var className = _ref.column.className,
              _ref$rowDatum = _ref.rowDatum,
              rowDatum = _ref$rowDatum === undefined ? {} : _ref$rowDatum;
          return cellClassName(className, rowDatum, true);
        },
        td: function td(props, _ref2) {
          var className = _ref2.column.className,
              _ref2$rowDatum = _ref2.rowDatum,
              rowDatum = _ref2$rowDatum === undefined ? {} : _ref2$rowDatum;
          return cellClassName(className, rowDatum, false);
        }
      });
    };

    return TableWithCellClassName;
  }(_tablePlugin.TablePlugin);
}