/*(c) Copyright 2015 Pivotal Software, Inc. All Rights Reserved.*/
'use strict';

exports.__esModule = true;
exports.ErrorAlert = exports.WarningAlert = exports.InfoAlert = exports.SuccessAlert = undefined;

var _extends2 = require('babel-runtime/helpers/extends');

var _extends3 = _interopRequireDefault(_extends2);

var _objectWithoutProperties2 = require('babel-runtime/helpers/objectWithoutProperties');

var _objectWithoutProperties3 = _interopRequireDefault(_objectWithoutProperties2);

var _classCallCheck2 = require('babel-runtime/helpers/classCallCheck');

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _possibleConstructorReturn2 = require('babel-runtime/helpers/possibleConstructorReturn');

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = require('babel-runtime/helpers/inherits');

var _inherits3 = _interopRequireDefault(_inherits2);

var _classnames = require('classnames');

var _classnames2 = _interopRequireDefault(_classnames);

var _react = require('react');

var _react2 = _interopRequireDefault(_react);

var _propTypes = require('prop-types');

var _propTypes2 = _interopRequireDefault(_propTypes);

var _helpers = require('../helpers');

var _iconography = require('../iconography');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var Alert = function (_React$PureComponent) {
  (0, _inherits3.default)(Alert, _React$PureComponent);

  function Alert(props, context) {
    (0, _classCallCheck3.default)(this, Alert);

    var _this = (0, _possibleConstructorReturn3.default)(this, _React$PureComponent.call(this, props, context));

    _this.handleAlertDismiss = function () {
      var onDismiss = _this.props.onDismiss;

      if (_this.props.onDismiss) onDismiss();
      _this.setState({ alertVisible: false });
    };

    _this.state = { alertVisible: true };
    return _this;
  }

  Alert.prototype.render = function render() {
    var _props = this.props,
        alertIcon = _props.alertIcon,
        bsStyle = _props.bsStyle,
        children = _props.children,
        closeLabel = _props.closeLabel,
        dismissable = _props.dismissable,
        __ignore = _props.onDismiss,
        show = _props.show,
        withIcon = _props.withIcon,
        others = (0, _objectWithoutProperties3.default)(_props, ['alertIcon', 'bsStyle', 'children', 'closeLabel', 'dismissable', 'onDismiss', 'show', 'withIcon']);


    var props = (0, _helpers.mergeProps)(others, {
      role: 'alert',
      className: (0, _classnames2.default)('alert', 'alert-' + bsStyle, { 'alert-dismissable': dismissable })
    });

    var visible = typeof show === 'undefined' ? this.state.alertVisible : show;

    if (!visible) return _react2.default.createElement('span', null);

    var iconColumn = void 0;
    if (withIcon) {
      iconColumn = _react2.default.createElement(
        'div',
        { className: 'col col-fixed pan mtm' },
        _react2.default.createElement(_iconography.Icon, { src: alertIcon })
      );
    }

    var dismissableColumn = void 0;
    if (dismissable) {
      dismissableColumn = _react2.default.createElement(
        'div',
        { className: 'col col-fixed pan' },
        _react2.default.createElement(
          'button',
          { type: 'button', className: 'btn close', 'aria-label': closeLabel, onClick: this.handleAlertDismiss },
          _react2.default.createElement(_iconography.Icon, {
            src: 'close' })
        )
      );
    }

    return _react2.default.createElement(
      'div',
      props,
      _react2.default.createElement(
        'div',
        { className: 'grid' },
        iconColumn,
        _react2.default.createElement(
          'div',
          { className: 'col col-middle' },
          children
        ),
        dismissableColumn
      )
    );
  };

  return Alert;
}(_react2.default.PureComponent);

Alert.propTypes = {
  alertIcon: _propTypes2.default.string,
  bsStyle: _propTypes2.default.string,
  closeLabel: _propTypes2.default.node,
  dismissable: _propTypes2.default.bool,
  onDismiss: _propTypes2.default.func,
  show: _propTypes2.default.bool,
  withIcon: _propTypes2.default.bool
};
Alert.defaultProps = {
  closeLabel: 'Close alert',
  dismissable: false,
  withIcon: false
};


var defAlert = function defAlert(props) {
  var _class, _temp;

  return _temp = _class = function (_React$Component) {
    (0, _inherits3.default)(_class, _React$Component);

    function _class() {
      (0, _classCallCheck3.default)(this, _class);
      return (0, _possibleConstructorReturn3.default)(this, _React$Component.apply(this, arguments));
    }

    _class.prototype.componentDidMount = function componentDidMount() {
      require('../../css/alerts');
    };

    _class.prototype.render = function render() {
      var _props2 = this.props,
          children = _props2.children,
          others = (0, _objectWithoutProperties3.default)(_props2, ['children']);

      return _react2.default.createElement(
        Alert,
        (0, _extends3.default)({}, props, others),
        _react2.default.createElement(
          'span',
          { className: 'sr-only' },
          (props.bsStyle === 'danger' ? 'error' : props.bsStyle) + ' alert message,'
        ),
        children
      );
    };

    return _class;
  }(_react2.default.Component), _class.propTypes = {
    dismissable: _propTypes2.default.oneOfType([_propTypes2.default.bool, _propTypes2.default.func]),
    withIcon: _propTypes2.default.bool
  }, _temp;
};

var SuccessAlert = exports.SuccessAlert = defAlert({ bsStyle: 'success', alertIcon: 'check_circle' });
var InfoAlert = exports.InfoAlert = defAlert({ bsStyle: 'info', alertIcon: 'info' });
var WarningAlert = exports.WarningAlert = defAlert({ bsStyle: 'warning', alertIcon: 'warning' });
var ErrorAlert = exports.ErrorAlert = defAlert({ bsStyle: 'danger', alertIcon: 'warning' });