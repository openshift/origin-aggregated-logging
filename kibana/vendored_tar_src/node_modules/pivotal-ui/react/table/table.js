/*(c) Copyright 2015 Pivotal Software, Inc. All Rights Reserved.*/
'use strict';

exports.__esModule = true;
exports.Table = undefined;

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

var _react = require('react');

var _react2 = _interopRequireDefault(_react);

var _tablePlugin = require('./table-plugin');

var _classnames = require('classnames');

var _classnames2 = _interopRequireDefault(_classnames);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var Table = exports.Table = function (_TablePlugin) {
  (0, _inherits3.default)(Table, _TablePlugin);

  function Table() {
    (0, _classCallCheck3.default)(this, Table);
    return (0, _possibleConstructorReturn3.default)(this, _TablePlugin.apply(this, arguments));
  }

  Table.prototype.componentDidMount = function componentDidMount() {
    require('../../css/tables');
  };

  Table.prototype.render = function render() {
    var _this2 = this;

    var _props = this.props,
        className = _props.className,
        columns = _props.columns,
        data = _props.data;


    var dataColumns = void 0;

    if (!columns && data.length > 0) {
      dataColumns = (0, _keys2.default)(data[0]).map(function (attribute) {
        return { attribute: attribute };
      });
    }

    var renderedColumns = (columns || dataColumns || []).map(function (attribute) {
      return typeof attribute === 'string' ? { attribute: attribute } : attribute;
    });

    var headers = renderedColumns.map(function (column, key) {
      var Th = _this2.plugTag('th', 'th');
      var children = column.displayName || column.attribute;
      var thContext = { column: column };
      return _react2.default.createElement(Th, (0, _extends3.default)({ key: key }, _this2.plugProps('th', { children: children }, thContext)));
    });

    var HeaderTr = this.plugTag('tr', 'tr');
    var headerTrContext = { isHeader: true, rowIndex: -1 };
    var headerRow = _react2.default.createElement(HeaderTr, this.plugProps('tr', { children: headers }, headerTrContext));

    var bodyCols = function bodyCols(rowDatum) {
      return renderedColumns.map(function (column, key) {
        var keys = column.attribute.split('.');
        var children = rowDatum;
        keys.forEach(function (key) {
          return children = (children || {})[key];
        });
        var tdContext = { column: column, rowDatum: rowDatum };
        var Td = _this2.plugTag('td', 'td', tdContext);
        return _react2.default.createElement(Td, (0, _extends3.default)({ key: key }, _this2.plugProps('td', { children: children }, tdContext)));
      });
    };

    var bodyRows = data.map(function (rowDatum, key) {
      var trContext = { rowDatum: rowDatum, isHeader: false, rowIndex: key };
      var Tr = _this2.plugTag('tr', 'tr', trContext);
      return _react2.default.createElement(Tr, (0, _extends3.default)({ key: key }, _this2.plugProps('tr', { children: bodyCols(rowDatum) }, trContext)));
    });

    var Table = this.plugTag('table', 'table');
    var tableChildren = [{
      method: 'thead', children: headerRow
    }, {
      method: 'tbody', children: bodyRows
    }, {
      method: 'tfoot', children: []
    }].map(function (_ref, key) {
      var method = _ref.method,
          children = _ref.children;

      var Tag = _this2.plugTag(method, method);
      return _react2.default.createElement(Tag, (0, _extends3.default)({}, _this2.plugProps(method, { children: children }), { key: key }));
    });

    return _react2.default.createElement(Table, this.plugProps('table', {
      className: (0, _classnames2.default)('table', className),
      children: tableChildren
    }));
  };

  return Table;
}(_tablePlugin.TablePlugin); // eslint-disable-next-line no-unused-vars


Table.defaultProps = (0, _extends3.default)({}, _tablePlugin.TablePlugin.defaultProps);