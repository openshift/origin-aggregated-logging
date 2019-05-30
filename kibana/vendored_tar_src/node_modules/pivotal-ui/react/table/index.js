/*(c) Copyright 2015 Pivotal Software, Inc. All Rights Reserved.*/
'use strict';

exports.__esModule = true;
exports.AdvancedTable = exports.SortableFlexTable = exports.FlexTable = exports.SortableTable = exports.withScrollableTbody = exports.withSorting = exports.withRowLink = exports.withRowDrawer = exports.withRowClassName = exports.withFooterRow = exports.withFlex = exports.withCellWidth = exports.withCellTooltip = exports.withCellRenderer = exports.withCellOnClick = exports.withCellLink = exports.withCellEllipsis = exports.withCellClassName = exports.TablePlugin = exports.Table = undefined;

var _table = require('./table');

Object.defineProperty(exports, 'Table', {
  enumerable: true,
  get: function get() {
    return _table.Table;
  }
});

var _tablePlugin = require('./table-plugin');

Object.defineProperty(exports, 'TablePlugin', {
  enumerable: true,
  get: function get() {
    return _tablePlugin.TablePlugin;
  }
});

var _cellClassName = require('./plugins/cell-class-name');

Object.defineProperty(exports, 'withCellClassName', {
  enumerable: true,
  get: function get() {
    return _cellClassName.withCellClassName;
  }
});

var _cellEllipsis = require('./plugins/cell-ellipsis');

Object.defineProperty(exports, 'withCellEllipsis', {
  enumerable: true,
  get: function get() {
    return _cellEllipsis.withCellEllipsis;
  }
});

var _cellLink = require('./plugins/cell-link');

Object.defineProperty(exports, 'withCellLink', {
  enumerable: true,
  get: function get() {
    return _cellLink.withCellLink;
  }
});

var _cellOnClick = require('./plugins/cell-on-click');

Object.defineProperty(exports, 'withCellOnClick', {
  enumerable: true,
  get: function get() {
    return _cellOnClick.withCellOnClick;
  }
});

var _cellRenderer = require('./plugins/cell-renderer');

Object.defineProperty(exports, 'withCellRenderer', {
  enumerable: true,
  get: function get() {
    return _cellRenderer.withCellRenderer;
  }
});

var _cellTooltip = require('./plugins/cell-tooltip');

Object.defineProperty(exports, 'withCellTooltip', {
  enumerable: true,
  get: function get() {
    return _cellTooltip.withCellTooltip;
  }
});

var _cellWidth = require('./plugins/cell-width');

Object.defineProperty(exports, 'withCellWidth', {
  enumerable: true,
  get: function get() {
    return _cellWidth.withCellWidth;
  }
});

var _flex = require('./plugins/flex');

Object.defineProperty(exports, 'withFlex', {
  enumerable: true,
  get: function get() {
    return _flex.withFlex;
  }
});

var _footerRow = require('./plugins/footer-row');

Object.defineProperty(exports, 'withFooterRow', {
  enumerable: true,
  get: function get() {
    return _footerRow.withFooterRow;
  }
});

var _rowClassName = require('./plugins/row-class-name');

Object.defineProperty(exports, 'withRowClassName', {
  enumerable: true,
  get: function get() {
    return _rowClassName.withRowClassName;
  }
});

var _rowDrawer = require('./plugins/row-drawer');

Object.defineProperty(exports, 'withRowDrawer', {
  enumerable: true,
  get: function get() {
    return _rowDrawer.withRowDrawer;
  }
});

var _rowLink = require('./plugins/row-link');

Object.defineProperty(exports, 'withRowLink', {
  enumerable: true,
  get: function get() {
    return _rowLink.withRowLink;
  }
});

var _sorting = require('./plugins/sorting');

Object.defineProperty(exports, 'withSorting', {
  enumerable: true,
  get: function get() {
    return _sorting.withSorting;
  }
});

var _scrollableTbody = require('./plugins/scrollable-tbody');

Object.defineProperty(exports, 'withScrollableTbody', {
  enumerable: true,
  get: function get() {
    return _scrollableTbody.withScrollableTbody;
  }
});

var _lodash = require('lodash.flow');

var _lodash2 = _interopRequireDefault(_lodash);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var SortableTable = exports.SortableTable = (0, _sorting.withSorting)(_table.Table);
var FlexTable = exports.FlexTable = (0, _flex.withFlex)(_table.Table);
var SortableFlexTable = exports.SortableFlexTable = (0, _flex.withFlex)(SortableTable);
var AdvancedTable = exports.AdvancedTable = (0, _lodash2.default)(_flex.withFlex, _cellLink.withCellLink, _cellClassName.withCellClassName, _cellEllipsis.withCellEllipsis, _cellOnClick.withCellOnClick, _cellRenderer.withCellRenderer, _cellTooltip.withCellTooltip, _cellWidth.withCellWidth, _footerRow.withFooterRow, _rowClassName.withRowClassName, _rowDrawer.withRowDrawer, _rowLink.withRowLink, _sorting.withSorting, _scrollableTbody.withScrollableTbody)(_table.Table);