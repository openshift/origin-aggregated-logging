/*(c) Copyright 2015 Pivotal Software, Inc. All Rights Reserved.*/
'use strict';

exports.__esModule = true;

var _extends2 = require('babel-runtime/helpers/extends');

var _extends3 = _interopRequireDefault(_extends2);

var _keys = require('babel-runtime/core-js/object/keys');

var _keys2 = _interopRequireDefault(_keys);

var _classCallCheck2 = require('babel-runtime/helpers/classCallCheck');

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _possibleConstructorReturn2 = require('babel-runtime/helpers/possibleConstructorReturn');

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = require('babel-runtime/helpers/inherits');

var _inherits3 = _interopRequireDefault(_inherits2);

exports.withCellRenderer = withCellRenderer;

var _react = require('react');

var _react2 = _interopRequireDefault(_react);

var _tablePlugin = require('../table-plugin');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

// eslint-disable-next-line no-unused-vars
function withCellRenderer(Table) {
  return function (_TablePlugin) {
    (0, _inherits3.default)(TableWithCellRenderer, _TablePlugin);

    function TableWithCellRenderer() {
      (0, _classCallCheck3.default)(this, TableWithCellRenderer);
      return (0, _possibleConstructorReturn3.default)(this, _TablePlugin.apply(this, arguments));
    }

    TableWithCellRenderer.prototype.render = function render() {
      return this.renderTable(Table, {
        td: function td(props, _ref) {
          var CellRenderer = _ref.column.CellRenderer,
              rowDatum = _ref.rowDatum;

          if (!CellRenderer) return;
          var cellRendererProps = {};
          if (CellRenderer.propTypes) {
            (0, _keys2.default)(CellRenderer.propTypes).forEach(function (key) {
              return cellRendererProps[key] = rowDatum[key];
            });
          } else {
            (0, _extends3.default)(cellRendererProps, rowDatum);
          }
          var children = _react2.default.createElement(CellRenderer, cellRendererProps);
          return { children: children };
        }
      });
    };

    return TableWithCellRenderer;
  }(_tablePlugin.TablePlugin);
}