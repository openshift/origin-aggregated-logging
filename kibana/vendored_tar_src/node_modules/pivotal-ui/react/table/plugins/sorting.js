/*(c) Copyright 2015 Pivotal Software, Inc. All Rights Reserved.*/
'use strict';

exports.__esModule = true;

var _keys = require('babel-runtime/core-js/object/keys');

var _keys2 = _interopRequireDefault(_keys);

var _classCallCheck2 = require('babel-runtime/helpers/classCallCheck');

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _possibleConstructorReturn2 = require('babel-runtime/helpers/possibleConstructorReturn');

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = require('babel-runtime/helpers/inherits');

var _inherits3 = _interopRequireDefault(_inherits2);

exports.withSorting = withSorting;

var _react = require('react');

var _react2 = _interopRequireDefault(_react);

var _classnames = require('classnames');

var _classnames2 = _interopRequireDefault(_classnames);

var _iconography = require('../../iconography');

var _lodash = require('lodash.sortby');

var _lodash2 = _interopRequireDefault(_lodash);

var _helpers = require('../../helpers');

var _tablePlugin = require('../table-plugin');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

// eslint-disable-next-line no-unused-vars
var SORT_ORDER = {
  asc: 0,
  desc: 1,
  none: 2
};

function withSorting(Table) {
  return function (_TablePlugin) {
    (0, _inherits3.default)(TableWithSorting, _TablePlugin);

    function TableWithSorting(props) {
      (0, _classCallCheck3.default)(this, TableWithSorting);

      var _this = (0, _possibleConstructorReturn3.default)(this, _TablePlugin.call(this, props));

      var _props$columns = props.columns,
          columns = _props$columns === undefined ? [] : _props$columns,
          defaultSort = props.defaultSort;


      _this.state = {
        sortColumn: (0, _helpers.find)(columns, function (_ref) {
          var sortable = _ref.sortable,
              attribute = _ref.attribute;
          return defaultSort ? attribute === defaultSort : sortable;
        }),
        sortOrder: SORT_ORDER.asc
      };
      return _this;
    }

    TableWithSorting.prototype.updateSort = function updateSort(column) {
      var sortColumn = this.state.sortColumn;

      var isSortColumn = column === sortColumn;

      if (isSortColumn) {
        var sortOrder = ++this.state.sortOrder % (0, _keys2.default)(SORT_ORDER).length;
        return this.setState({ sortOrder: sortOrder });
      }

      this.setState({
        sortColumn: column.sortable && column,
        sortOrder: SORT_ORDER.asc
      });
    };

    TableWithSorting.prototype.sort = function sort() {
      var data = this.props.data;
      var _state = this.state,
          sortColumn = _state.sortColumn,
          sortOrder = _state.sortOrder;

      if (!sortColumn || sortOrder === SORT_ORDER.none) return data;
      var sorted = (0, _lodash2.default)(data, function (datum) {
        var rankFunction = sortColumn.sortBy || function (i) {
          return i;
        };
        return rankFunction(datum[sortColumn.attribute]);
      });

      if (sortOrder === SORT_ORDER.desc) sorted.reverse();

      return sorted;
    };

    TableWithSorting.prototype.render = function render() {
      var _this2 = this;

      return this.renderTable(Table, {
        table: function table() {
          return { className: 'table-sortable' };
        },
        th: function th(props, _ref2) {
          var column = _ref2.column,
              sortable = _ref2.column.sortable;

          if (!sortable) return props;

          var oldChildren = props.children;
          var _state2 = _this2.state,
              sortColumn = _state2.sortColumn,
              sortOrder = _state2.sortOrder;

          var isSortColumn = column === sortColumn;
          var className = void 0,
              icon = void 0;

          if (isSortColumn) {
            className = ['sorted-asc', 'sorted-desc', ''][sortOrder];
            icon = [_react2.default.createElement(_iconography.Icon, { key: 0, verticalAlign: 'baseline', src: 'arrow_drop_up' }), _react2.default.createElement(_iconography.Icon, { key: 0, verticalAlign: 'baseline', src: 'arrow_drop_down' }), null][sortOrder];
          }

          var onClick = function onClick() {
            return _this2.updateSort(column);
          };
          var children = _react2.default.createElement(
            'div',
            null,
            oldChildren,
            icon
          );

          return {
            className: (0, _classnames2.default)({ sortable: sortable }, className),
            disabled: !sortable,
            children: children,
            onClick: onClick,
            onKeyDown: function onKeyDown(_ref3) {
              var key = _ref3.key;
              return key === 'Enter' && onClick();
            },
            role: 'button',
            tabIndex: 0
          };
        },
        data: this.sort()
      });
    };

    return TableWithSorting;
  }(_tablePlugin.TablePlugin);
}