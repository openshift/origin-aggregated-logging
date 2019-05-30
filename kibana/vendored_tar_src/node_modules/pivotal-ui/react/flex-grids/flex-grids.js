/*(c) Copyright 2015 Pivotal Software, Inc. All Rights Reserved.*/
'use strict';

exports.__esModule = true;
exports.FlexCol = exports.Grid = undefined;

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

var _helpers = require('../helpers');

var _classnames6 = require('classnames');

var _classnames7 = _interopRequireDefault(_classnames6);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var Grid = exports.Grid = function (_React$PureComponent) {
  (0, _inherits3.default)(Grid, _React$PureComponent);

  function Grid() {
    (0, _classCallCheck3.default)(this, Grid);
    return (0, _possibleConstructorReturn3.default)(this, _React$PureComponent.apply(this, arguments));
  }

  Grid.prototype.componentDidMount = function componentDidMount() {
    require('../../css/flex-grids');
  };

  Grid.prototype.render = function render() {
    var _props = this.props,
        gutter = _props.gutter,
        props = (0, _objectWithoutProperties3.default)(_props, ['gutter']);

    var newProps = (0, _helpers.mergeProps)(props, { className: (0, _classnames7.default)('grid', gutter ? '' : 'grid-nogutter') });
    return _react2.default.createElement('div', newProps);
  };

  return Grid;
}(_react2.default.PureComponent);

Grid.propTypes = {
  gutter: _propTypes2.default.bool
};
Grid.defaultProps = {
  gutter: true
};

var FlexCol = exports.FlexCol = function (_React$Component) {
  (0, _inherits3.default)(FlexCol, _React$Component);

  function FlexCol() {
    (0, _classCallCheck3.default)(this, FlexCol);
    return (0, _possibleConstructorReturn3.default)(this, _React$Component.apply(this, arguments));
  }

  FlexCol.prototype.componentDidMount = function componentDidMount() {
    require('../../css/flex-grids');
  };

  FlexCol.prototype.render = function render() {
    var _classnames, _classnames2, _classnames3, _classnames4, _classnames5;

    var _props2 = this.props,
        col = _props2.col,
        fixed = _props2.fixed,
        grow = _props2.grow,
        alignment = _props2.alignment,
        contentAlignment = _props2.contentAlignment,
        breakpoint = _props2.breakpoint,
        other = (0, _objectWithoutProperties3.default)(_props2, ['col', 'fixed', 'grow', 'alignment', 'contentAlignment', 'breakpoint']);


    var colClassName = (0, _classnames7.default)((_classnames = {}, _classnames['col-' + col] = col, _classnames));

    var fixedClassName = (0, _classnames7.default)({
      'col-fixed': fixed
    });

    var growClassName = (0, _classnames7.default)((_classnames2 = {}, _classnames2['col-grow-' + grow] = grow, _classnames2));

    var alignmentClassName = (0, _classnames7.default)((_classnames3 = {}, _classnames3['col-align-' + alignment] = alignment, _classnames3));

    var contentAlignmentClassName = (0, _classnames7.default)((_classnames4 = {}, _classnames4['col-' + contentAlignment] = contentAlignment, _classnames4));

    var breakpointClassName = (0, _classnames7.default)((_classnames5 = {}, _classnames5['col-' + breakpoint] = breakpoint, _classnames5));

    var className = (0, _classnames7.default)('col', colClassName, fixedClassName, growClassName, alignmentClassName, contentAlignmentClassName, breakpointClassName);

    var newProps = (0, _helpers.mergeProps)(other, { className: className });
    return _react2.default.createElement('div', newProps);
  };

  return FlexCol;
}(_react2.default.Component);

FlexCol.propTypes = {
  col: _propTypes2.default.number,
  fixed: _propTypes2.default.bool,
  grow: _propTypes2.default.number,
  alignment: _propTypes2.default.oneOf(['top', 'middle', 'bottom']),
  contentAlignment: _propTypes2.default.oneOf(['top', 'middle', 'bottom']),
  breakpoint: _propTypes2.default.oneOf(['sm', 'md', 'lg'])
};
;