/*(c) Copyright 2015 Pivotal Software, Inc. All Rights Reserved.*/
'use strict';

exports.__esModule = true;
exports.TileLayoutItem = exports.TileLayout = undefined;

var _objectWithoutProperties2 = require('babel-runtime/helpers/objectWithoutProperties');

var _objectWithoutProperties3 = _interopRequireDefault(_objectWithoutProperties2);

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

var _helpers = require('../helpers');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var TileLayout = exports.TileLayout = function (_React$Component) {
  (0, _inherits3.default)(TileLayout, _React$Component);

  function TileLayout() {
    var _temp, _this, _ret;

    (0, _classCallCheck3.default)(this, TileLayout);

    for (var _len = arguments.length, args = Array(_len), _key = 0; _key < _len; _key++) {
      args[_key] = arguments[_key];
    }

    return _ret = (_temp = (_this = (0, _possibleConstructorReturn3.default)(this, _React$Component.call.apply(_React$Component, [this].concat(args))), _this), _this.getColumnClasses = function (columns) {
      if (columns instanceof Object) {
        var classes = [];

        for (var breakpoint in columns) {
          if (columns.hasOwnProperty(breakpoint)) {
            classes.push('tile-layout-' + breakpoint + '-' + columns[breakpoint]);
          }
        }

        return classes;
      } else {
        return 'tile-layout-xs-' + columns;
      }
    }, _temp), (0, _possibleConstructorReturn3.default)(_this, _ret);
  }

  TileLayout.prototype.componentDidMount = function componentDidMount() {
    require('../../css/tile-layout');
  };

  TileLayout.prototype.render = function render() {
    var _props = this.props,
        children = _props.children,
        columns = _props.columns,
        noGutter = _props.noGutter,
        others = (0, _objectWithoutProperties3.default)(_props, ['children', 'columns', 'noGutter']);


    var classes = (0, _classnames2.default)(this.getColumnClasses(columns), noGutter ? null : 'tile-gutter', 'tile-layout');
    var props = (0, _helpers.mergeProps)({ className: classes }, others);
    return _react2.default.createElement(
      'div',
      props,
      children
    );
  };

  return TileLayout;
}(_react2.default.Component);

TileLayout.propTypes = {
  columns: _propTypes2.default.oneOfType([_propTypes2.default.number, _propTypes2.default.object]),
  noGutter: _propTypes2.default.bool
};

var TileLayoutItem = exports.TileLayoutItem = function (_React$Component2) {
  (0, _inherits3.default)(TileLayoutItem, _React$Component2);

  function TileLayoutItem() {
    (0, _classCallCheck3.default)(this, TileLayoutItem);
    return (0, _possibleConstructorReturn3.default)(this, _React$Component2.apply(this, arguments));
  }

  TileLayoutItem.prototype.componentDidMount = function componentDidMount() {
    require('../../css/tile-layout');
  };

  TileLayoutItem.prototype.render = function render() {
    return _react2.default.createElement('div', (0, _helpers.mergeProps)({ className: 'tile-item' }, this.props));
  };

  return TileLayoutItem;
}(_react2.default.Component);