/*(c) Copyright 2015 Pivotal Software, Inc. All Rights Reserved.*/
'use strict';

exports.__esModule = true;
exports.CopyToClipboard = undefined;

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

var _clipboardHelper = require('./clipboard-helper');

var _helpers = require('../helpers');

var _propTypes = require('prop-types');

var _propTypes2 = _interopRequireDefault(_propTypes);

var _tooltip = require('../tooltip');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var CopyToClipboard = exports.CopyToClipboard = function (_React$PureComponent) {
  (0, _inherits3.default)(CopyToClipboard, _React$PureComponent);

  function CopyToClipboard() {
    var _temp, _this, _ret;

    (0, _classCallCheck3.default)(this, CopyToClipboard);

    for (var _len = arguments.length, args = Array(_len), _key = 0; _key < _len; _key++) {
      args[_key] = arguments[_key];
    }

    return _ret = (_temp = (_this = (0, _possibleConstructorReturn3.default)(this, _React$PureComponent.call.apply(_React$PureComponent, [this].concat(args))), _this), _this.click = function (_ref, e) {
      var props = _ref.props,
          text = _ref.text;

      var window = _this.props.getWindow();
      (0, _clipboardHelper.copy)(window, window.document, text);
      var onClick = props.onClick;

      if (onClick) onClick(e);
    }, _temp), (0, _possibleConstructorReturn3.default)(_this, _ret);
  }

  CopyToClipboard.prototype.componentDidMount = function componentDidMount() {
    require('../../css/copy-to-clipboard');
  };

  CopyToClipboard.prototype.render = function render() {
    var _props = this.props,
        children = _props.children,
        text = _props.text,
        onClick = _props.onClick,
        getWindow = _props.getWindow,
        _props$tooltip = _props.tooltip,
        tooltip = _props$tooltip === undefined ? "Copied" : _props$tooltip,
        others = (0, _objectWithoutProperties3.default)(_props, ['children', 'text', 'onClick', 'getWindow', 'tooltip']);

    var obj = { props: this.props, text: null };

    var anchorProps = (0, _helpers.mergeProps)(others, {
      className: 'copy-to-clipboard',
      onClick: this.click.bind(undefined, obj),
      role: 'button'
    });

    return _react2.default.createElement(
      'a',
      anchorProps,
      _react2.default.createElement(
        _tooltip.TooltipTrigger,
        { tooltip: tooltip, trigger: "click" },
        _react2.default.createElement(
          'span',
          { className: 'sr-only', ref: function ref(_ref2) {
              return obj.text = _ref2;
            } },
          text
        ),
        children
      )
    );
  };

  return CopyToClipboard;
}(_react2.default.PureComponent);

CopyToClipboard.propTypes = {
  text: _propTypes2.default.string.isRequired,
  onClick: _propTypes2.default.func,
  getWindow: _propTypes2.default.func,
  tooltip: _propTypes2.default.string
};
CopyToClipboard.defaultProps = {
  getWindow: function getWindow() {
    return window;
  }
};