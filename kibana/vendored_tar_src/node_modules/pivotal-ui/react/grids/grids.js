/*(c) Copyright 2015 Pivotal Software, Inc. All Rights Reserved.*/
'use strict';

exports.__esModule = true;
exports.Col = exports.Row = undefined;

var _objectWithoutProperties2 = require('babel-runtime/helpers/objectWithoutProperties');

var _objectWithoutProperties3 = _interopRequireDefault(_objectWithoutProperties2);

var _classCallCheck2 = require('babel-runtime/helpers/classCallCheck');

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _possibleConstructorReturn2 = require('babel-runtime/helpers/possibleConstructorReturn');

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = require('babel-runtime/helpers/inherits');

var _inherits3 = _interopRequireDefault(_inherits2);

var _classnames5 = require('classnames');

var _classnames6 = _interopRequireDefault(_classnames5);

var _react = require('react');

var _react2 = _interopRequireDefault(_react);

var _propTypes = require('prop-types');

var _propTypes2 = _interopRequireDefault(_propTypes);

var _helpers = require('../helpers');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var Row = exports.Row = function (_React$PureComponent) {
  (0, _inherits3.default)(Row, _React$PureComponent);

  function Row() {
    (0, _classCallCheck3.default)(this, Row);
    return (0, _possibleConstructorReturn3.default)(this, _React$PureComponent.apply(this, arguments));
  }

  Row.prototype.componentDidMount = function componentDidMount() {
    require('../../css/grids');
  };

  Row.prototype.render = function render() {
    var _props = this.props,
        Component = _props.componentClass,
        gutter = _props.gutter,
        other = (0, _objectWithoutProperties3.default)(_props, ['componentClass', 'gutter']);

    var gutterClass = {
      'row-gutter-md': gutter === 'md',
      'row-gutter-sm': gutter === 'sm'
    };
    var props = (0, _helpers.mergeProps)(other, { className: (0, _classnames6.default)('row', gutterClass) });
    return _react2.default.createElement(Component, props);
  };

  return Row;
}(_react2.default.PureComponent);

Row.propTypes = {
  componentClass: _propTypes2.default.oneOfType([_propTypes2.default.string, _propTypes2.default.func]),
  gutter: _propTypes2.default.oneOf(['sm', 'md', 'lg'])
};
Row.defaultProps = {
  componentClass: 'div'
};

var Col = exports.Col = function (_React$Component) {
  (0, _inherits3.default)(Col, _React$Component);

  function Col() {
    (0, _classCallCheck3.default)(this, Col);
    return (0, _possibleConstructorReturn3.default)(this, _React$Component.apply(this, arguments));
  }

  Col.prototype.componentDidMount = function componentDidMount() {
    require('../../css/grids');
  };

  Col.prototype.render = function render() {
    var _classnames, _classnames2, _classnames3, _classnames4;

    var _props2 = this.props,
        Component = _props2.componentClass,
        xs = _props2.xs,
        sm = _props2.sm,
        md = _props2.md,
        lg = _props2.lg,
        xsHidden = _props2.xsHidden,
        smHidden = _props2.smHidden,
        mdHidden = _props2.mdHidden,
        lgHidden = _props2.lgHidden,
        xsOffset = _props2.xsOffset,
        smOffset = _props2.smOffset,
        mdOffset = _props2.mdOffset,
        lgOffset = _props2.lgOffset,
        xsPush = _props2.xsPush,
        smPush = _props2.smPush,
        mdPush = _props2.mdPush,
        lgPush = _props2.lgPush,
        xsPull = _props2.xsPull,
        smPull = _props2.smPull,
        mdPull = _props2.mdPull,
        lgPull = _props2.lgPull,
        other = (0, _objectWithoutProperties3.default)(_props2, ['componentClass', 'xs', 'sm', 'md', 'lg', 'xsHidden', 'smHidden', 'mdHidden', 'lgHidden', 'xsOffset', 'smOffset', 'mdOffset', 'lgOffset', 'xsPush', 'smPush', 'mdPush', 'lgPush', 'xsPull', 'smPull', 'mdPull', 'lgPull']);


    var sizeClassName = (0, _classnames6.default)((_classnames = {}, _classnames['col-xs-' + xs] = xs, _classnames['col-sm-' + sm] = sm, _classnames['col-md-' + md] = md, _classnames['col-lg-' + lg] = lg, _classnames));

    var hiddenClassName = (0, _classnames6.default)({
      'hidden-xs': xsHidden,
      'hidden-sm': smHidden,
      'hidden-md': mdHidden,
      'hidden-lg': lgHidden
    });

    var offsetClassName = (0, _classnames6.default)((_classnames2 = {}, _classnames2['col-xs-offset-' + xsOffset] = xsOffset, _classnames2['col-sm-offset-' + smOffset] = smOffset, _classnames2['col-md-offset-' + mdOffset] = mdOffset, _classnames2['col-lg-offset-' + lgOffset] = lgOffset, _classnames2));

    var pushClassName = (0, _classnames6.default)((_classnames3 = {}, _classnames3['col-xs-push-' + xsPush] = xsPush, _classnames3['col-sm-push-' + smPush] = smPush, _classnames3['col-md-push-' + mdPush] = mdPush, _classnames3['col-lg-push-' + lgPush] = lgPush, _classnames3));

    var pullClassName = (0, _classnames6.default)((_classnames4 = {}, _classnames4['col-xs-pull-' + xsPull] = xsPull, _classnames4['col-sm-pull-' + smPull] = smPull, _classnames4['col-md-pull-' + mdPull] = mdPull, _classnames4['col-lg-pull-' + lgPull] = lgPull, _classnames4));

    var props = (0, _helpers.mergeProps)(other, {
      className: (0, _classnames6.default)(sizeClassName, hiddenClassName, offsetClassName, pushClassName, pullClassName)
    });

    return _react2.default.createElement(Component, props);
  };

  return Col;
}(_react2.default.Component);

Col.propTypes = {
  componentClass: _propTypes2.default.oneOfType([_propTypes2.default.string, _propTypes2.default.func]),
  xs: _propTypes2.default.number,
  sm: _propTypes2.default.number,
  lg: _propTypes2.default.number,
  md: _propTypes2.default.number,
  xsHidden: _propTypes2.default.bool,
  smHidden: _propTypes2.default.bool,
  mdHidden: _propTypes2.default.bool,
  lgHidden: _propTypes2.default.bool,
  xsOffset: _propTypes2.default.number,
  smOffset: _propTypes2.default.number,
  mdOffset: _propTypes2.default.number,
  lgOffset: _propTypes2.default.number,
  xsPush: _propTypes2.default.number,
  smPush: _propTypes2.default.number,
  mdPush: _propTypes2.default.number,
  lgPush: _propTypes2.default.number,
  xsPull: _propTypes2.default.number,
  smPull: _propTypes2.default.number,
  mdPull: _propTypes2.default.number,
  lgPull: _propTypes2.default.number
};
Col.defaultProps = {
  componentClass: 'div'
};