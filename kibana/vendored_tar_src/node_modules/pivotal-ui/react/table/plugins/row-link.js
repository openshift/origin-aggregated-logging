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

exports.withRowLink = withRowLink;

var _react = require('react');

var _react2 = _interopRequireDefault(_react);

var _propTypes = require('prop-types');

var _propTypes2 = _interopRequireDefault(_propTypes);

var _tablePlugin = require('../table-plugin');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function withRowLink(Table) {
  var _class, _temp;

  return _temp = _class = function (_TablePlugin) {
    (0, _inherits3.default)(TableWithRowLink, _TablePlugin);

    function TableWithRowLink() {
      (0, _classCallCheck3.default)(this, TableWithRowLink);
      return (0, _possibleConstructorReturn3.default)(this, _TablePlugin.apply(this, arguments));
    }

    TableWithRowLink.prototype.render = function render() {
      var _props = this.props,
          _props$rowLink = _props.rowLink;
      _props$rowLink = _props$rowLink === undefined ? {} : _props$rowLink;
      var link = _props$rowLink.link,
          _onClick = _props$rowLink.onClick,
          props = (0, _objectWithoutProperties3.default)(_props, ['rowLink']);

      return this.renderTable(Table, {
        trTag: function trTag(_ref) {
          var rowDatum = _ref.rowDatum;
          return rowDatum && link && link(rowDatum) && 'a';
        },
        tr: function tr(props, _ref2) {
          var rowDatum = _ref2.rowDatum;

          if (!rowDatum || !link) return;

          var href = link(rowDatum);
          if (!href) return;

          return { href: href, onClick: function onClick(e) {
              return _onClick(e, rowDatum);
            } };
        }
      }, props);
    };

    return TableWithRowLink;
  }(_tablePlugin.TablePlugin), _class.propTypes = { rowLink: _propTypes2.default.object }, _temp;
} // eslint-disable-next-line no-unused-vars