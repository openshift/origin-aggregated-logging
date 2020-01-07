/*(c) Copyright 2015 Pivotal Software, Inc. All Rights Reserved.*/
'use strict';

exports.__esModule = true;
exports.TablePlugin = undefined;

var _objectWithoutProperties2 = require('babel-runtime/helpers/objectWithoutProperties');

var _objectWithoutProperties3 = _interopRequireDefault(_objectWithoutProperties2);

var _extends2 = require('babel-runtime/helpers/extends');

var _extends3 = _interopRequireDefault(_extends2);

var _classCallCheck2 = require('babel-runtime/helpers/classCallCheck');

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _possibleConstructorReturn2 = require('babel-runtime/helpers/possibleConstructorReturn');

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = require('babel-runtime/helpers/inherits');

var _inherits3 = _interopRequireDefault(_inherits2);

var _react = require('react');

var _react2 = _interopRequireDefault(_react);

var _propTypes = require('prop-types');

var _propTypes2 = _interopRequireDefault(_propTypes);

var _classnames = require('classnames');

var _classnames2 = _interopRequireDefault(_classnames);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var TablePlugin = exports.TablePlugin = function (_React$Component) {
  (0, _inherits3.default)(TablePlugin, _React$Component);

  function TablePlugin(props) {
    (0, _classCallCheck3.default)(this, TablePlugin);

    var _this = (0, _possibleConstructorReturn3.default)(this, _React$Component.call(this, props));

    _this.plugTag = _this.plugTag.bind(_this);
    _this.plugProps = _this.plugProps.bind(_this);
    return _this;
  }

  TablePlugin.prototype.plugTag = function plugTag(method, tag) {
    var pluginContext = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : {};

    var pluggedTag = this.props[method + 'Tag'] && this.props[method + 'Tag'](pluginContext);
    return this.props.plugTag(method, pluggedTag, pluginContext) || tag;
  };

  TablePlugin.prototype.mergeProps = function mergeProps() {
    var props1 = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : {};
    var props2 = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : {};

    return (0, _extends3.default)({}, props1, props2, {
      className: (0, _classnames2.default)(props1.className, props2.className),
      style: (0, _extends3.default)({}, props1.style, props2.style)
    });
  };

  TablePlugin.prototype.plugProps = function plugProps(method) {
    var props = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : {};
    var pluginContext = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : {};

    var pluggedProps = this.props[method] && this.mergeProps(props, this.props[method](props, pluginContext));
    return this.props.plugProps(method, pluggedProps || props, pluginContext);
  };

  TablePlugin.prototype.renderTable = function renderTable(Table, methods) {
    var props = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : this.props;
    var plugTag = props.plugTag,
        tableTag = props.tableTag,
        theadTag = props.theadTag,
        tbodyTag = props.tbodyTag,
        tfootTag = props.tfootTag,
        trTag = props.trTag,
        thTag = props.thTag,
        tdTag = props.tdTag,
        plugProps = props.plugProps,
        table = props.table,
        thead = props.thead,
        tbody = props.tbody,
        tfoot = props.tfoot,
        tr = props.tr,
        th = props.th,
        td = props.td,
        others = (0, _objectWithoutProperties3.default)(props, ['plugTag', 'tableTag', 'theadTag', 'tbodyTag', 'tfootTag', 'trTag', 'thTag', 'tdTag', 'plugProps', 'table', 'thead', 'tbody', 'tfoot', 'tr', 'th', 'td']);

    return _react2.default.createElement(Table, (0, _extends3.default)({}, others, methods, { plugTag: this.plugTag, plugProps: this.plugProps }));
  };

  TablePlugin.prototype.render = function render() {
    return null;
  };

  return TablePlugin;
}(_react2.default.Component);

TablePlugin.propTypes = {
  columns: _propTypes2.default.array,
  data: _propTypes2.default.array.isRequired,
  plugTag: _propTypes2.default.func.isRequired,
  tableTag: _propTypes2.default.func,
  theadTag: _propTypes2.default.func,
  tbodyTag: _propTypes2.default.func,
  tfootTag: _propTypes2.default.func,
  trTag: _propTypes2.default.func,
  thTag: _propTypes2.default.func,
  tdTag: _propTypes2.default.func,
  plugProps: _propTypes2.default.func.isRequired,
  table: _propTypes2.default.func,
  thead: _propTypes2.default.func,
  tbody: _propTypes2.default.func,
  tfoot: _propTypes2.default.func,
  tr: _propTypes2.default.func,
  th: _propTypes2.default.func,
  td: _propTypes2.default.func
};
TablePlugin.defaultProps = {
  plugTag: function plugTag(method, tag) {
    return tag;
  },
  plugProps: function plugProps(method, props) {
    return props;
  }
};