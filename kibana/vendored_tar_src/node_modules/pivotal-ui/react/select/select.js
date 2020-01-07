/*(c) Copyright 2015 Pivotal Software, Inc. All Rights Reserved.*/
'use strict';

exports.__esModule = true;
exports.Select = undefined;

var _extends2 = require('babel-runtime/helpers/extends');

var _extends3 = _interopRequireDefault(_extends2);

var _typeof2 = require('babel-runtime/helpers/typeof');

var _typeof3 = _interopRequireDefault(_typeof2);

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

var _buttons = require('../buttons');

var _helpers = require('../helpers');

var _iconography = require('../iconography');

var _mixins = require('../mixins');

var _mixins2 = _interopRequireDefault(_mixins);

var _scrim_mixin = require('../mixins/mixins/scrim_mixin');

var _scrim_mixin2 = _interopRequireDefault(_scrim_mixin);

var _transition_mixin = require('../mixins/mixins/transition_mixin');

var _transition_mixin2 = _interopRequireDefault(_transition_mixin);

var _classnames = require('classnames');

var _classnames2 = _interopRequireDefault(_classnames);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var isBlank = function isBlank(value) {
  return value === null || value === undefined;
};

var Select = exports.Select = function (_mixin$with) {
  (0, _inherits3.default)(Select, _mixin$with);

  function Select(props, context) {
    (0, _classCallCheck3.default)(this, Select);

    var _this = (0, _possibleConstructorReturn3.default)(this, _mixin$with.call(this, props, context));

    _this.toggle = function () {
      return _this.setState({ open: !_this.state.open });
    };

    _this.select = function (e) {
      var value = e.target.getAttribute('data-value');

      _this.setState({
        open: false,
        uncontrolledValue: value
      }, _this.props.onChange && _this.props.onChange(e, value));
    };

    _this.scrimClick = function () {
      return _this.setState({ open: false });
    };

    var defaultValue = props.defaultValue;

    _this.state = {
      open: false,
      uncontrolledValue: defaultValue
    };
    return _this;
  }

  Select.prototype.componentDidMount = function componentDidMount() {
    _mixin$with.prototype.componentDidMount.call(this);
    require('../../css/select');
  };

  Select.prototype.render = function render() {
    var _this2 = this;

    var _state = this.state,
        open = _state.open,
        uncontrolledValue = _state.uncontrolledValue;

    var _mergeProps = (0, _helpers.mergeProps)(this.props, { className: ['select', { open: open }] }),
        controlledValue = _mergeProps.value,
        __IGNORE2 = _mergeProps.defaultValue,
        onChange = _mergeProps.onChange,
        name = _mergeProps.name,
        options = _mergeProps.options,
        onEntered = _mergeProps.onEntered,
        onExited = _mergeProps.onExited,
        props = (0, _objectWithoutProperties3.default)(_mergeProps, ['value', 'defaultValue', 'onChange', 'name', 'options', 'onEntered', 'onExited']);

    var toggleValue = isBlank(controlledValue) ? uncontrolledValue : controlledValue;

    var _options$reduce = options.reduce(function (memo, option) {
      var _ref = (typeof option === 'undefined' ? 'undefined' : (0, _typeof3.default)(option)) === 'object' ? option : { value: option, label: option },
          value = _ref.value,
          label = _ref.label;

      var selected = value === toggleValue;
      if (selected) memo.toggleLabel = label;
      var className = (0, _classnames2.default)({ selected: value === toggleValue }, 'option');
      memo.selectOptions.push(_react2.default.createElement(
        'li',
        {
          className: className,
          key: value,
          role: 'button',
          'data-value': value,
          onClick: _this2.select
        },
        label
      ));
      return memo;
    }, { toggleLabel: toggleValue, selectOptions: [] }),
        toggleLabel = _options$reduce.toggleLabel,
        selectOptions = _options$reduce.selectOptions;

    var list = _react2.default.createElement(
      'ul',
      null,
      selectOptions
    );

    return _react2.default.createElement(
      'div',
      props,
      _react2.default.createElement('input', (0, _extends3.default)({ type: 'hidden' }, { name: name, value: toggleValue })),
      _react2.default.createElement(
        _buttons.DefaultButton,
        { type: 'button', className: 'select-toggle', onClick: this.toggle },
        _react2.default.createElement(
          'span',
          { className: 'select-toggle-label' },
          toggleLabel
        ),
        _react2.default.createElement(_iconography.Icon, { src: 'select_chevrons' })
      ),
      list,
      _react2.default.createElement(
        'div',
        { className: 'select-menu' },
        list
      )
    );
  };

  return Select;
}((0, _mixins2.default)(_react2.default.Component).with(_scrim_mixin2.default, _transition_mixin2.default));

Select.propTypes = {
  defaultValue: _propTypes2.default.any,
  name: _propTypes2.default.string,
  onChange: _propTypes2.default.func,
  onEntered: _propTypes2.default.func,
  onExited: _propTypes2.default.func,
  options: _propTypes2.default.array.isRequired,
  value: _propTypes2.default.any
};