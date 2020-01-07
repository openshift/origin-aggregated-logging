/*(c) Copyright 2015 Pivotal Software, Inc. All Rights Reserved.*/
'use strict';

exports.__esModule = true;

var _classCallCheck2 = require('babel-runtime/helpers/classCallCheck');

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _possibleConstructorReturn2 = require('babel-runtime/helpers/possibleConstructorReturn');

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = require('babel-runtime/helpers/inherits');

var _inherits3 = _interopRequireDefault(_inherits2);

exports.withCellWidth = withCellWidth;

var _react = require('react');

var _react2 = _interopRequireDefault(_react);

var _tablePlugin = require('../table-plugin');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

// eslint-disable-next-line no-unused-vars
function withCellWidth(Table) {
  var cellWidth = function cellWidth(width) {
    return width && { className: 'col-fixed', style: { width: width } };
  };

  return function (_TablePlugin) {
    (0, _inherits3.default)(TableWithCellWidth, _TablePlugin);

    function TableWithCellWidth() {
      (0, _classCallCheck3.default)(this, TableWithCellWidth);
      return (0, _possibleConstructorReturn3.default)(this, _TablePlugin.apply(this, arguments));
    }

    TableWithCellWidth.prototype.render = function render() {
      return this.renderTable(Table, {
        th: function th(props, _ref) {
          var width = _ref.column.width;
          return cellWidth(width);
        },
        td: function td(props, _ref2) {
          var width = _ref2.column.width;
          return cellWidth(width);
        }
      });
    };

    return TableWithCellWidth;
  }(_tablePlugin.TablePlugin);
}