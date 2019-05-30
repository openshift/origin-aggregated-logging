/*(c) Copyright 2015 Pivotal Software, Inc. All Rights Reserved.*/
'use strict';

exports.__esModule = true;
exports.ModalFooter = exports.ModalBody = exports.Modal = exports.BaseModal = undefined;

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

var _typeof2 = require('babel-runtime/helpers/typeof');

var _typeof3 = _interopRequireDefault(_typeof2);

var _weakMap = require('babel-runtime/core-js/weak-map');

var _weakMap2 = _interopRequireDefault(_weakMap);

var _animation_mixin = require('../mixins/mixins/animation_mixin');

var _animation_mixin2 = _interopRequireDefault(_animation_mixin);

var _classnames2 = require('classnames');

var _classnames3 = _interopRequireDefault(_classnames2);

var _react = require('react');

var _react2 = _interopRequireDefault(_react);

var _propTypes = require('prop-types');

var _propTypes2 = _interopRequireDefault(_propTypes);

var _mixins = require('../mixins');

var _mixins2 = _interopRequireDefault(_mixins);

var _helpers = require('../helpers');

var _iconography = require('../iconography');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var ESC_KEY = 27;
var privates = new _weakMap2.default();

function bodyNotAllowedToScroll(document) {
  if ((typeof document === 'undefined' ? 'undefined' : (0, _typeof3.default)(document)) !== 'object') return;
  var body = document.getElementsByTagName('body')[0];
  if (!body.classList.contains('pui-no-scroll')) {
    body.classList.add('pui-no-scroll');
  }
}

function bodyIsAllowedToScroll(document) {
  if ((typeof document === 'undefined' ? 'undefined' : (0, _typeof3.default)(document)) === 'object') document.getElementsByTagName('body')[0].classList.remove('pui-no-scroll');
}

var BaseModal = exports.BaseModal = function (_mixin$with) {
  (0, _inherits3.default)(BaseModal, _mixin$with);

  function BaseModal(props, context) {
    (0, _classCallCheck3.default)(this, BaseModal);

    var _this = (0, _possibleConstructorReturn3.default)(this, _mixin$with.call(this, props, context));

    _this.modalClicked = function (e) {
      if (!_this.dialog) return;
      if (_this.dialog.contains(e.target)) return;
      _this.props.onHide(e);
    };

    _this.onKeyDown = function (e) {
      if (_this.props.keyboard && e.keyCode === ESC_KEY) {
        _this.props.onHide(e);
      }
    };

    _this.focus = function () {
      return setTimeout(function () {
        _this.modal && _this.modal.focus();
      }, 1);
    };

    privates.set(_this, { fractionShown: 0 });
    var document = _this.props.getDocument();
    _this.props.show ? bodyNotAllowedToScroll(document) : bodyIsAllowedToScroll(document);
    return _this;
  }

  BaseModal.prototype.componentDidMount = function componentDidMount() {
    require('../../css/modals');
    var document = this.props.getDocument();
    if ((typeof document === 'undefined' ? 'undefined' : (0, _typeof3.default)(document)) === 'object') document.addEventListener('keydown', this.onKeyDown);
  };

  BaseModal.prototype.componentWillUnmount = function componentWillUnmount() {
    if (_mixin$with.prototype.componentWillUnmount) _mixin$with.prototype.componentWillUnmount.call(this);
    var document = this.props.getDocument();
    if ((typeof document === 'undefined' ? 'undefined' : (0, _typeof3.default)(document)) !== 'object') return;
    document.removeEventListener('keydown', this.onKeyDown);
    bodyIsAllowedToScroll(document);
  };

  BaseModal.prototype.render = function render() {
    var _this2 = this,
        _classnames;

    var _props = this.props,
        acquireFocus = _props.acquireFocus,
        animation = _props.animation,
        size = _props.size,
        children = _props.children,
        dialogClassName = _props.dialogClassName,
        __ignore1 = _props.keyboard,
        onEntered = _props.onEntered,
        onExited = _props.onExited,
        onHide = _props.onHide,
        show = _props.show,
        title = _props.title,
        __ignore2 = _props.getDocument,
        modalProps = (0, _objectWithoutProperties3.default)(_props, ['acquireFocus', 'animation', 'size', 'children', 'dialogClassName', 'keyboard', 'onEntered', 'onExited', 'onHide', 'show', 'title', 'getDocument']);

    this.props.show ? bodyNotAllowedToScroll() : bodyIsAllowedToScroll();

    var animationTime = animation ? BaseModal.ANIMATION_TIME : 0;
    var fractionDestination = show ? 1 : 0;

    var _privates$get = privates.get(this),
        oldFractionShown = _privates$get.fractionShown;

    var fractionShown = this.animate('fractionShown', fractionDestination, animationTime, {
      startValue: 0,
      easing: 'easeOutQuad'
    });

    privates.set(this, (0, _extends3.default)({}, privates.get(this), { fractionShown: fractionShown }));

    if (oldFractionShown < 1 && fractionShown === 1) {
      if (acquireFocus) this.focus();
      onEntered && onEntered();
    }

    if (oldFractionShown > 0 && fractionShown === 0) {
      onExited && onExited();
    }

    if (fractionShown === 0 && !show) return null;

    var props = (0, _helpers.mergeProps)(modalProps, {
      className: 'modal fade in',
      role: 'dialog',
      style: { display: 'block' },
      onMouseDown: this.modalClicked,
      tabIndex: -1
    });

    var dialogStyle = {
      marginTop: 50 * fractionShown + 'px'
    };

    var modalSize = { small: 'sm', sm: 'sm', large: 'lg', lg: 'lg' }[size];
    var modalSizeClass = 'modal-' + modalSize;

    return _react2.default.createElement(
      'div',
      { className: 'modal-wrapper', role: 'dialog' },
      _react2.default.createElement('div', { className: 'modal-backdrop fade in', style: { opacity: fractionShown * 0.8 }, onClick: onHide }),
      _react2.default.createElement(
        'div',
        (0, _extends3.default)({}, props, { ref: function ref(_ref2) {
            return _this2.modal = _ref2;
          } }),
        _react2.default.createElement(
          'div',
          { className: (0, _classnames3.default)('modal-dialog', dialogClassName, (_classnames = {}, _classnames[modalSizeClass] = modalSize, _classnames)),
            style: dialogStyle, ref: function ref(_ref) {
              return _this2.dialog = _ref;
            } },
          _react2.default.createElement(
            'div',
            { className: 'modal-content' },
            _react2.default.createElement(
              'div',
              { className: 'modal-header' },
              _react2.default.createElement(
                'h3',
                { className: 'modal-title em-high' },
                title
              ),
              _react2.default.createElement(
                'div',
                { className: 'modal-close' },
                _react2.default.createElement(
                  'button',
                  { className: 'btn btn-icon', onClick: onHide, type: 'button' },
                  _react2.default.createElement(_iconography.Icon, { src: 'close' })
                )
              )
            ),
            children
          )
        )
      )
    );
  };

  return BaseModal;
}((0, _mixins2.default)(_react2.default.PureComponent).with(_animation_mixin2.default));

BaseModal.propTypes = {
  acquireFocus: _propTypes2.default.bool,
  animation: _propTypes2.default.bool,
  size: _propTypes2.default.string,
  dialogClassName: _propTypes2.default.string,
  keyboard: _propTypes2.default.bool,
  onEntered: _propTypes2.default.func,
  onExited: _propTypes2.default.func,
  onHide: _propTypes2.default.func,
  show: _propTypes2.default.bool,
  title: _propTypes2.default.node,
  getDocument: _propTypes2.default.func
};
BaseModal.defaultProps = {
  acquireFocus: true,
  animation: true,
  keyboard: true,
  onHide: function onHide() {},
  getDocument: function getDocument() {
    return global.document;
  }
};
BaseModal.ANIMATION_TIME = 300;
BaseModal.ESC_KEY = ESC_KEY;

var Modal = exports.Modal = function (_React$PureComponent) {
  (0, _inherits3.default)(Modal, _React$PureComponent);

  function Modal(props, context) {
    (0, _classCallCheck3.default)(this, Modal);

    var _this3 = (0, _possibleConstructorReturn3.default)(this, _React$PureComponent.call(this, props, context));

    _this3.open = function () {
      return _this3.setState({ isVisible: true });
    };

    _this3.close = function () {
      return _this3.setState({ isVisible: false });
    };

    _this3.state = { isVisible: false };
    return _this3;
  }

  Modal.prototype.componentDidMount = function componentDidMount() {
    require('../../css/modals');
  }; // This is required for testing


  // This is required for testing

  Modal.prototype.render = function render() {
    return _react2.default.createElement(BaseModal, (0, _extends3.default)({ show: this.state.isVisible, onHide: this.close.bind(this) }, this.props));
  };

  return Modal;
}(_react2.default.PureComponent);

var ModalBody = exports.ModalBody = function (_React$PureComponent2) {
  (0, _inherits3.default)(ModalBody, _React$PureComponent2);

  function ModalBody() {
    (0, _classCallCheck3.default)(this, ModalBody);
    return (0, _possibleConstructorReturn3.default)(this, _React$PureComponent2.apply(this, arguments));
  }

  ModalBody.prototype.componentDidMount = function componentDidMount() {
    require('../../css/modals');
  };

  ModalBody.prototype.render = function render() {
    return _react2.default.createElement(
      'div',
      (0, _helpers.mergeProps)(this.props, { className: 'modal-body' }),
      this.props.children
    );
  };

  return ModalBody;
}(_react2.default.PureComponent);

var ModalFooter = exports.ModalFooter = function (_React$PureComponent3) {
  (0, _inherits3.default)(ModalFooter, _React$PureComponent3);

  function ModalFooter() {
    (0, _classCallCheck3.default)(this, ModalFooter);
    return (0, _possibleConstructorReturn3.default)(this, _React$PureComponent3.apply(this, arguments));
  }

  ModalFooter.prototype.componentDidMount = function componentDidMount() {
    require('../../css/modals');
  };

  ModalFooter.prototype.render = function render() {
    return _react2.default.createElement(
      'div',
      (0, _helpers.mergeProps)(this.props, { className: 'modal-footer' }),
      this.props.children
    );
  };

  return ModalFooter;
}(_react2.default.PureComponent);