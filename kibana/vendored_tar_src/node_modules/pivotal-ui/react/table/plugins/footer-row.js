/*(c) Copyright 2015 Pivotal Software, Inc. All Rights Reserved.*/
'use strict';

exports.__esModule = true;

var _objectWithoutProperties2 = require('babel-runtime/helpers/objectWithoutProperties');

var _objectWithoutProperties3 = _interopRequireDefault(_objectWithoutProperties2);

var _classCallCheck2 = require('babel-runtime/helpers/classCallCheck');

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _possibleConstructorReturn2 = require('babel-runtime/helpers/possibleConstructorReturn');

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = require('babel-runtime/helpers/inherits');

var _inherits3 = _interopRequireDefault(_inherits2);

exports.withFooterRow = withFooterRow;

var _react = require('react');

var _react2 = _interopRequireDefault(_react);

var _propTypes = require('prop-types');

var _propTypes2 = _interopRequireDefault(_propTypes);

var _tablePlugin = require('../table-plugin');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function withFooterRow(Table) {
  var _class, _temp;

  return _temp = _class = function (_TablePlugin) {
    (0, _inherits3.default)(TableWithFooterRow, _TablePlugin);

    function TableWithFooterRow() {
      (0, _classCallCheck3.default)(this, TableWithFooterRow);
      return (0, _possibleConstructorReturn3.default)(this, _TablePlugin.apply(this, arguments));
    }

    TableWithFooterRow.prototype.render = function render() {
      var _props = this.props,
          footerRow = _props.footerRow,
          props = (0, _objectWithoutProperties3.default)(_props, ['footerRow']);

      var children = [].concat(props.children, [footerRow]).filter(function (el) {
        return el;
      }).map(function (el, key) {
        return _react2.default.cloneElement(el, { key: key });
      });
      return this.renderTable(Table, {
        tfoot: function tfoot(props) {
          return { children: children };
        }
      }, props);
    };

    return TableWithFooterRow;
  }(_tablePlugin.TablePlugin), _class.propTypes = { footerRow: _propTypes2.default.any }, _temp;
} // eslint-disable-next-line no-unused-vars