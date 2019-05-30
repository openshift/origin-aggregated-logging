/*(c) Copyright 2015 Pivotal Software, Inc. All Rights Reserved.*/
'use strict';

exports.__esModule = true;

var _classCallCheck2 = require('babel-runtime/helpers/classCallCheck');

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _possibleConstructorReturn2 = require('babel-runtime/helpers/possibleConstructorReturn');

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = require('babel-runtime/helpers/inherits');

var _inherits3 = _interopRequireDefault(_inherits2);

exports.withCellEllipsis = withCellEllipsis;

var _react = require('react');

var _react2 = _interopRequireDefault(_react);

var _tablePlugin = require('../table-plugin');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

// eslint-disable-next-line no-unused-vars
function withCellEllipsis(Table) {
  return function (_TablePlugin) {
    (0, _inherits3.default)(TableWithCellEllipsis, _TablePlugin);

    function TableWithCellEllipsis() {
      (0, _classCallCheck3.default)(this, TableWithCellEllipsis);
      return (0, _possibleConstructorReturn3.default)(this, _TablePlugin.apply(this, arguments));
    }

    TableWithCellEllipsis.prototype.render = function render() {
      return this.renderTable(Table, {
        td: function td(props, _ref) {
          var ellipsis = _ref.column.ellipsis;
          var oldChildren = props.children;

          if (!ellipsis) return;
          var children = _react2.default.createElement(
            'span',
            { className: 'type-ellipsis' },
            oldChildren
          );
          return { children: children };
        }
      });
    };

    return TableWithCellEllipsis;
  }(_tablePlugin.TablePlugin);
}