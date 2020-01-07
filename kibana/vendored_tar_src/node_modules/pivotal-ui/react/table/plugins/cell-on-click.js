/*(c) Copyright 2015 Pivotal Software, Inc. All Rights Reserved.*/
'use strict';

exports.__esModule = true;

var _classCallCheck2 = require('babel-runtime/helpers/classCallCheck');

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _possibleConstructorReturn2 = require('babel-runtime/helpers/possibleConstructorReturn');

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = require('babel-runtime/helpers/inherits');

var _inherits3 = _interopRequireDefault(_inherits2);

exports.withCellOnClick = withCellOnClick;

var _react = require('react');

var _react2 = _interopRequireDefault(_react);

var _tablePlugin = require('../table-plugin');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

// eslint-disable-next-line no-unused-vars
function withCellOnClick(Table) {
  return function (_TablePlugin) {
    (0, _inherits3.default)(TableWithCellOnClick, _TablePlugin);

    function TableWithCellOnClick() {
      (0, _classCallCheck3.default)(this, TableWithCellOnClick);
      return (0, _possibleConstructorReturn3.default)(this, _TablePlugin.apply(this, arguments));
    }

    TableWithCellOnClick.prototype.render = function render() {
      return this.renderTable(Table, {
        td: function td(props, _ref) {
          var _onClick = _ref.column.onClick,
              rowDatum = _ref.rowDatum;
          return _onClick && { onClick: function onClick(e) {
              return _onClick(e, rowDatum);
            } };
        }
      });
    };

    return TableWithCellOnClick;
  }(_tablePlugin.TablePlugin);
}