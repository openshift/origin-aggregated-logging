/*(c) Copyright 2015 Pivotal Software, Inc. All Rights Reserved.*/
'use strict';

exports.__esModule = true;

var _classCallCheck2 = require('babel-runtime/helpers/classCallCheck');

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _possibleConstructorReturn2 = require('babel-runtime/helpers/possibleConstructorReturn');

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = require('babel-runtime/helpers/inherits');

var _inherits3 = _interopRequireDefault(_inherits2);

exports.withFlex = withFlex;

var _react = require('react');

var _react2 = _interopRequireDefault(_react);

var _tablePlugin = require('../table-plugin');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

// eslint-disable-next-line no-unused-vars
function withFlex(Table) {
  return function (_TablePlugin) {
    (0, _inherits3.default)(TableWithFlex, _TablePlugin);

    function TableWithFlex() {
      (0, _classCallCheck3.default)(this, TableWithFlex);
      return (0, _possibleConstructorReturn3.default)(this, _TablePlugin.apply(this, arguments));
    }

    TableWithFlex.prototype.componentDidMount = function componentDidMount() {
      require('../../../css/flex-grids');
    };

    TableWithFlex.prototype.render = function render() {
      return this.renderTable(Table, {
        tableTag: function tableTag() {
          return 'div';
        },
        theadTag: function theadTag() {
          return 'div';
        },
        tbodyTag: function tbodyTag() {
          return 'div';
        },
        tfootTag: function tfootTag() {
          return 'div';
        },
        trTag: function trTag() {
          return 'div';
        },
        thTag: function thTag() {
          return 'div';
        },
        tdTag: function tdTag() {
          return 'div';
        },
        thead: function thead() {
          return { className: 'thead' };
        },
        tbody: function tbody() {
          return { className: 'tbody' };
        },
        tfoot: function tfoot() {
          return { className: 'tfoot' };
        },
        tr: function tr() {
          return { className: 'tr grid' };
        },
        th: function th() {
          return { className: 'th col' };
        },
        td: function td() {
          return { className: 'td col' };
        }
      });
    };

    return TableWithFlex;
  }(_tablePlugin.TablePlugin);
}