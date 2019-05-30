/*(c) Copyright 2015 Pivotal Software, Inc. All Rights Reserved.*/
'use strict';

exports.__esModule = true;

var _classCallCheck2 = require('babel-runtime/helpers/classCallCheck');

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _possibleConstructorReturn2 = require('babel-runtime/helpers/possibleConstructorReturn');

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = require('babel-runtime/helpers/inherits');

var _inherits3 = _interopRequireDefault(_inherits2);

exports.withCellLink = withCellLink;

var _react = require('react');

var _react2 = _interopRequireDefault(_react);

var _tablePlugin = require('../table-plugin');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

// eslint-disable-next-line no-unused-vars
function withCellLink(Table) {
  return function (_TablePlugin) {
    (0, _inherits3.default)(TableWithCellLink, _TablePlugin);

    function TableWithCellLink() {
      (0, _classCallCheck3.default)(this, TableWithCellLink);
      return (0, _possibleConstructorReturn3.default)(this, _TablePlugin.apply(this, arguments));
    }

    TableWithCellLink.prototype.render = function render() {
      return this.renderTable(Table, {
        tdTag: function tdTag(_ref) {
          var link = _ref.column.link,
              rowDatum = _ref.rowDatum;
          return link && link(rowDatum) && 'a';
        },
        td: function td(props, _ref2) {
          var _ref2$column = _ref2.column,
              link = _ref2$column.link,
              target = _ref2$column.target,
              rowDatum = _ref2.rowDatum;

          if (!link) return;

          var href = link(rowDatum);
          if (!href) return;

          var oldChildren = props.children;

          if (!oldChildren) return { href: href, target: target };

          return { children: _react2.default.createElement(
              'span',
              { className: 'hover-underline' },
              oldChildren
            ), href: href, target: target };
        }
      });
    };

    return TableWithCellLink;
  }(_tablePlugin.TablePlugin);
}