/*(c) Copyright 2015 Pivotal Software, Inc. All Rights Reserved.*/
'use strict';

exports.__esModule = true;
exports.Form = undefined;

var _objectWithoutProperties2 = require('babel-runtime/helpers/objectWithoutProperties');

var _objectWithoutProperties3 = _interopRequireDefault(_objectWithoutProperties2);

var _keys = require('babel-runtime/core-js/object/keys');

var _keys2 = _interopRequireDefault(_keys);

var _extends6 = require('babel-runtime/helpers/extends');

var _extends7 = _interopRequireDefault(_extends6);

var _classCallCheck2 = require('babel-runtime/helpers/classCallCheck');

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _possibleConstructorReturn2 = require('babel-runtime/helpers/possibleConstructorReturn');

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = require('babel-runtime/helpers/inherits');

var _inherits3 = _interopRequireDefault(_inherits2);

var _stringify = require('babel-runtime/core-js/json/stringify');

var _stringify2 = _interopRequireDefault(_stringify);

var _react = require('react');

var _react2 = _interopRequireDefault(_react);

var _propTypes = require('prop-types');

var _propTypes2 = _interopRequireDefault(_propTypes);

var _classnames = require('classnames');

var _classnames2 = _interopRequireDefault(_classnames);

var _deepEqual = require('deep-equal');

var _deepEqual2 = _interopRequireDefault(_deepEqual);

var _formRow = require('./form-row');

var _helpers = require('../helpers');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var deepClone = function deepClone(o) {
  return JSON.parse((0, _stringify2.default)(o));
};
var noop = function noop() {};

function isPromise() {
  var promise = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : {};

  return typeof promise.then === 'function';
}

var Form = exports.Form = function (_React$Component) {
  (0, _inherits3.default)(Form, _React$Component);

  function Form(props) {
    (0, _classCallCheck3.default)(this, Form);

    var _this = (0, _possibleConstructorReturn3.default)(this, _React$Component.call(this, props));

    var requiredFields = [];
    var initial = {};

    var children = props.children;

    _react2.default.Children.toArray(children).filter(function (r) {
      return r;
    }).forEach(function (formRow) {
      return _react2.default.Children.toArray(formRow.props.children).filter(function (c) {
        return c;
      }).forEach(function (formCol) {
        if (!formCol.props) return;
        var _formCol$props = formCol.props,
            name = _formCol$props.name,
            optional = _formCol$props.optional,
            initialValue = _formCol$props.initialValue;

        if (name) {
          optional || requiredFields.push(name);
          initial[name] = typeof initialValue === 'undefined' ? '' : initialValue;
        }
      });
    });

    var current = deepClone(initial);
    _this.state = {
      initial: initial,
      current: current,
      submitting: false,
      errors: {},
      requiredFields: requiredFields
    };

    _this.onChangeCheckbox = _this.onChangeCheckbox.bind(_this);
    _this.onChange = _this.onChange.bind(_this);
    _this.onBlur = _this.onBlur.bind(_this);
    _this.reset = _this.reset.bind(_this);
    _this.canSubmit = _this.canSubmit.bind(_this);
    _this.canReset = _this.canReset.bind(_this);
    _this.onSubmit = _this.onSubmit.bind(_this);
    _this.setState = _this.setState.bind(_this);
    return _this;
  }

  Form.prototype.componentDidMount = function componentDidMount() {
    require('../../css/forms');
  };

  Form.prototype.componentWillUnmount = function componentWillUnmount() {
    this.props.onModified(false);
  };

  Form.prototype.onChangeCheckbox = function onChangeCheckbox(name) {
    var _this2 = this;

    return function () {
      var _extends2;

      _this2.setState({
        current: (0, _extends7.default)({}, _this2.state.current, (_extends2 = {}, _extends2[name] = !_this2.state.current[name], _extends2))
      });
    };
  };

  Form.prototype.onChange = function onChange(name, validator) {
    var _this3 = this;

    var initial = this.state.initial;
    var onModified = this.props.onModified;

    return function () {
      var _extends3;

      for (var _len = arguments.length, args = Array(_len), _key = 0; _key < _len; _key++) {
        args[_key] = arguments[_key];
      }

      var value = args.length > 1 ? args[1] : args[0] && args[0].target.value;
      var nextState = {
        current: (0, _extends7.default)({}, _this3.state.current, (_extends3 = {}, _extends3[name] = value, _extends3))
      };
      var error = validator && validator(value);
      if (!error) {
        var _extends4;

        nextState.errors = (0, _extends7.default)({}, _this3.state.errors, (_extends4 = {}, _extends4[name] = undefined, _extends4));
      }
      _this3.setState(nextState);
      onModified(!(0, _deepEqual2.default)(initial, nextState.current));
    };
  };

  Form.prototype.onBlur = function onBlur(_ref) {
    var _this4 = this;

    var name = _ref.name,
        validator = _ref.validator;

    return function (_ref2) {
      var _extends5;

      var value = _ref2.target.value;

      var error = validator(value);
      _this4.setState({
        errors: (0, _extends7.default)({}, _this4.state.errors, (_extends5 = {}, _extends5[name] = error, _extends5))
      });
    };
  };

  Form.prototype.canSubmit = function canSubmit() {
    var _this5 = this;

    var _ref3 = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : {},
        checkRequiredFields = _ref3.checkRequiredFields;

    var children = this.props.children;
    var _state = this.state,
        initial = _state.initial,
        current = _state.current,
        submitting = _state.submitting,
        requiredFields = _state.requiredFields;

    return !submitting && (0, _helpers.find)((0, _keys2.default)(initial), function (key) {
      return !(0, _deepEqual2.default)(initial[key], current[key]);
    }) && (checkRequiredFields ? checkRequiredFields(this.state.current) : !(0, _helpers.find)(requiredFields, function (key) {
      return !current[key];
    })) && !(0, _helpers.find)(_react2.default.Children.toArray(children), function (row) {
      return (0, _helpers.find)(_react2.default.Children.toArray(row.props.children), function (_ref4) {
        var _ref4$props = _ref4.props,
            name = _ref4$props.name,
            validator = _ref4$props.validator;
        return validator && validator(_this5.state.current[name]);
      });
    });
  };

  Form.prototype.canReset = function canReset() {
    var _state2 = this.state,
        submitting = _state2.submitting,
        initial = _state2.initial,
        current = _state2.current;

    return !submitting && !(0, _deepEqual2.default)(initial, current);
  };

  Form.prototype.onSubmit = function onSubmit(e) {
    var _this6 = this;

    e && e.preventDefault();
    var _props = this.props,
        onSubmit = _props.onSubmit,
        onSubmitError = _props.onSubmitError,
        afterSubmit = _props.afterSubmit,
        onModified = _props.onModified,
        resetOnSubmit = _props.resetOnSubmit;
    var _state3 = this.state,
        initial = _state3.initial,
        current = _state3.current;

    this.setState({ submitting: true });
    var nextState = { submitting: false };

    var onSuccess = function onSuccess(response) {
      _this6.setState((0, _extends7.default)({}, nextState, {
        current: resetOnSubmit ? deepClone(initial) : current,
        initial: resetOnSubmit ? initial : deepClone(current),
        errors: {}
      }));
      var after = function after() {
        return afterSubmit({ state: _this6.state, setState: _this6.setState, response: response, reset: _this6.reset });
      };
      var onModifiedPromise = onModified(false);
      return isPromise(onModifiedPromise) ? onModifiedPromise.then(after) : after();
    };

    var onError = function onError(e) {
      _this6.setState((0, _extends7.default)({}, nextState, { errors: onSubmitError && onSubmitError(e) || {} }));
    };

    try {
      var afterSubmitPromise = onSubmit({ initial: initial, current: current });
      if (isPromise(afterSubmitPromise)) {
        return afterSubmitPromise.then(onSuccess).catch(onError);
      } else {
        return onSuccess(afterSubmitPromise);
      }
    } catch (e) {
      onError(e);
      throw e;
    }
  };

  Form.prototype.reset = function reset() {
    var onModified = this.props.onModified;
    var initial = this.state.initial;

    onModified(false);
    this.setState({ current: deepClone(initial), errors: {} });
  };

  Form.prototype.render = function render() {
    var _this7 = this;

    var _props2 = this.props,
        className = _props2.className,
        children = _props2.children,
        onSubmit = _props2.onSubmit,
        resetOnSubmit = _props2.resetOnSubmit,
        onModified = _props2.onModified,
        onSubmitError = _props2.onSubmitError,
        afterSubmit = _props2.afterSubmit,
        other = (0, _objectWithoutProperties3.default)(_props2, ['className', 'children', 'onSubmit', 'resetOnSubmit', 'onModified', 'onSubmitError', 'afterSubmit']);
    var submitting = this.state.submitting;

    var filteredChildren = _react2.default.Children.toArray(children).filter(function (child) {
      var childIsFormRow = child.type === _formRow.FormRow || child.type.prototype instanceof _formRow.FormRow;
      if (!childIsFormRow) {
        console.warn('Child of type "' + child.type + '" will not be rendered. A Form\'s children should be of type FormRow.');
      }
      return childIsFormRow;
    });

    return _react2.default.createElement(
      'form',
      (0, _extends7.default)({ className: (0, _classnames2.default)('form', className), onSubmit: this.onSubmit }, other),
      _react2.default.createElement(
        'fieldset',
        { disabled: submitting },
        filteredChildren.map(function (formRow, key) {
          return _react2.default.cloneElement(formRow, {
            key: key,
            state: _this7.state,
            setState: _this7.setState,
            canSubmit: _this7.canSubmit,
            onSubmit: _this7.onSubmit,
            canReset: _this7.canReset,
            reset: _this7.reset,
            onChange: _this7.onChange,
            onBlur: _this7.onBlur,
            onChangeCheckbox: _this7.onChangeCheckbox
          });
        })
      )
    );
  };

  return Form;
}(_react2.default.Component);

Form.propTypes = {
  onModified: _propTypes2.default.func.isRequired,
  onSubmit: _propTypes2.default.func.isRequired,
  onSubmitError: _propTypes2.default.func.isRequired,
  afterSubmit: _propTypes2.default.func.isRequired,
  resetOnSubmit: _propTypes2.default.bool
};
Form.defaultProps = {
  onModified: noop,
  onSubmit: noop,
  onSubmitError: function onSubmitError() {
    return {};
  },
  afterSubmit: noop
};