/*(c) Copyright 2015 Pivotal Software, Inc. All Rights Reserved.*/
'use strict';

exports.__esModule = true;
exports.InverseDivider = exports.Divider = undefined;

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

var _react = require('react');

var _react2 = _interopRequireDefault(_react);

var _propTypes = require('prop-types');

var _propTypes2 = _interopRequireDefault(_propTypes);

var _helpers = require('../helpers');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var Divider = exports.Divider = function (_React$PureComponent) {
  (0, _inherits3.default)(Divider, _React$PureComponent);

  function Divider() {
    (0, _classCallCheck3.default)(this, Divider);
    return (0, _possibleConstructorReturn3.default)(this, _React$PureComponent.apply(this, arguments));
  }

  Divider.prototype.componentDidMount = function componentDidMount() {
    require('../../css/dividers');
  };

  Divider.prototype.render = function render() {
    var _props = this.props,
        inverse = _props.inverse,
        size = _props.size,
        others = (0, _objectWithoutProperties3.default)(_props, ['inverse', 'size']);

    var dividerClass = {
      'divider-1': inverse && size !== 'large',
      'divider-2': inverse && size === 'large',
      'divider-alternate-1': !inverse && size !== 'large',
      'divider-alternate-2': !inverse && size === 'large'
    };

    var props = (0, _helpers.mergeProps)(others, { className: dividerClass });

    return _react2.default.createElement('hr', props);
  };

  return Divider;
}(_react2.default.PureComponent);

Divider.propTypes = {
  inverse: _propTypes2.default.bool,
  size: _propTypes2.default.oneOf(['large'])
};


var defDivider = function defDivider(props) {
  var _class, _temp;

  return _temp = _class = function (_React$PureComponent2) {
    (0, _inherits3.default)(_class, _React$PureComponent2);

    function _class() {
      (0, _classCallCheck3.default)(this, _class);
      return (0, _possibleConstructorReturn3.default)(this, _React$PureComponent2.apply(this, arguments));
    }

    _class.prototype.render = function render() {
      return _react2.default.createElement(Divider, (0, _extends3.default)({}, props, this.props));
    };

    return _class;
  }(_react2.default.PureComponent), _class.propTypes = {
    inverse: _propTypes2.default.bool,
    size: _propTypes2.default.oneOf(['large'])
  }, _temp;
};

var InverseDivider = exports.InverseDivider = defDivider({ inverse: true });