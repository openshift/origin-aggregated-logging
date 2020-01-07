/*(c) Copyright 2015 Pivotal Software, Inc. All Rights Reserved.*/
'use strict';

exports.__esModule = true;

var _classCallCheck2 = require('babel-runtime/helpers/classCallCheck');

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _possibleConstructorReturn2 = require('babel-runtime/helpers/possibleConstructorReturn');

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = require('babel-runtime/helpers/inherits');

var _inherits3 = _interopRequireDefault(_inherits2);

exports.withCellTooltip = withCellTooltip;

var _react = require('react');

var _react2 = _interopRequireDefault(_react);

var _tooltip = require('../../tooltip');

var _overlayTrigger = require('../../overlay-trigger');

var _iconography = require('../../iconography');

var _tablePlugin = require('../table-plugin');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function withCellTooltip(Table) {
  function cellTooltip(props, tooltip, rowDatum, isHeader) {
    var oldChildren = props.children;

    if (!tooltip) return;

    var _ref = tooltip({ isHeader: isHeader }, rowDatum) || {},
        text = _ref.text,
        size = _ref.size,
        theme = _ref.theme,
        showIcon = _ref.showIcon;

    if (!text) return;

    var overlay = _react2.default.createElement(
      _tooltip.Tooltip,
      { size: size },
      text
    );
    var children = _react2.default.createElement(
      _overlayTrigger.OverlayTrigger,
      {
        placement: 'top',
        overlay: overlay,
        theme: theme
      },
      _react2.default.createElement(
        'span',
        { className: 'overlay-trigger' },
        _react2.default.createElement(
          'span',
          null,
          oldChildren
        ),
        showIcon && _react2.default.createElement(_iconography.Icon, {
          src: 'info_outline',
          verticalAlign: 'baseline',
          className: 'mlm'
        })
      )
    );

    return { children: children };
  }

  return function (_TablePlugin) {
    (0, _inherits3.default)(TableWithCellTooltip, _TablePlugin);

    function TableWithCellTooltip() {
      (0, _classCallCheck3.default)(this, TableWithCellTooltip);
      return (0, _possibleConstructorReturn3.default)(this, _TablePlugin.apply(this, arguments));
    }

    TableWithCellTooltip.prototype.render = function render() {
      return this.renderTable(Table, {
        th: function th(props, _ref2) {
          var tooltip = _ref2.column.tooltip,
              rowDatum = _ref2.rowDatum;
          return cellTooltip(props, tooltip, rowDatum, true);
        },
        td: function td(props, _ref3) {
          var tooltip = _ref3.column.tooltip,
              rowDatum = _ref3.rowDatum;
          return cellTooltip(props, tooltip, rowDatum, false);
        }
      });
    };

    return TableWithCellTooltip;
  }(_tablePlugin.TablePlugin);
} // eslint-disable-next-line no-unused-vars