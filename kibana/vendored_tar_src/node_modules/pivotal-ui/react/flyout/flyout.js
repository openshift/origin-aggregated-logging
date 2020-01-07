/*(c) Copyright 2015 Pivotal Software, Inc. All Rights Reserved.*/
'use strict';

exports.__esModule = true;
exports.Flyout = undefined;

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

var _buttons = require('../buttons');

var _iconography = require('../iconography');

var _classnames = require('classnames');

var _classnames2 = _interopRequireDefault(_classnames);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var Flyout = exports.Flyout = function (_React$Component) {
  (0, _inherits3.default)(Flyout, _React$Component);

  function Flyout() {
    (0, _classCallCheck3.default)(this, Flyout);
    return (0, _possibleConstructorReturn3.default)(this, _React$Component.apply(this, arguments));
  }

  Flyout.prototype.componentDidMount = function componentDidMount() {
    require('../../css/flyout');
  };

  Flyout.prototype.componentWillUnmount = function componentWillUnmount() {
    this.props.close();
  };

  Flyout.prototype.render = function render() {
    var _props = this.props,
        children = _props.children,
        open = _props.open,
        close = _props.close,
        header = _props.header,
        width = _props.width;


    var right = void 0;
    if (width) {
      var value = parseFloat(width);
      var unit = width.substr(('' + value).length);
      right = '' + -0.8 * value + unit;
    }

    return _react2.default.createElement(
      'div',
      { className: (0, _classnames2.default)('flyout', {
          'flyout-open': open
        }) },
      _react2.default.createElement(
        'div',
        { className: 'flyout-content', style: { width: width, right: right } },
        _react2.default.createElement(
          'div',
          { className: 'flyout-header grid' },
          _react2.default.createElement(
            'div',
            { className: 'col col-fixed' },
            _react2.default.createElement(
              _buttons.DefaultButton,
              {
                className: 'flyout-close',
                iconOnly: true,
                flat: true,
                onClick: function onClick() {
                  return close();
                }
              },
              _react2.default.createElement(_iconography.Icon, { src: 'close' })
            )
          ),
          _react2.default.createElement(
            'div',
            { className: 'col' },
            header
          )
        ),
        _react2.default.createElement(
          'div',
          { className: 'flyout-body' },
          children
        )
      )
    );
  };

  return Flyout;
}(_react2.default.Component);

Flyout.propTypes = {
  open: _propTypes2.default.bool,
  close: _propTypes2.default.func.isRequired,
  width: _propTypes2.default.string,
  children: _propTypes2.default.any,
  header: _propTypes2.default.any
};
Flyout.defaultProps = {
  close: function close() {}
};