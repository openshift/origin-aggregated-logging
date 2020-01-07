/*(c) Copyright 2015 Pivotal Software, Inc. All Rights Reserved.*/
'use strict';

exports.__esModule = true;

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

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

exports.default = function (ParentClass) {
  var _class, _temp;

  return _temp = _class = function (_ParentClass) {
    (0, _inherits3.default)(Transition, _ParentClass);

    function Transition() {
      (0, _classCallCheck3.default)(this, Transition);
      return (0, _possibleConstructorReturn3.default)(this, _ParentClass.apply(this, arguments));
    }

    Transition.prototype.componentWillUpdate = function componentWillUpdate(nextProps, nextState) {
      _ParentClass.prototype.componentWillUpdate && _ParentClass.prototype.componentWillUpdate.call(this, nextProps, nextState);

      var open = nextState.open;
      var onEntered = nextProps.onEntered,
          onExited = nextProps.onExited;


      var transitionCallback = open ? onEntered : onExited;
      var transitioning = open !== this.state.open;
      if (transitioning && transitionCallback) transitionCallback();
    };

    return Transition;
  }(ParentClass), _class.propTypes = {
    onEntered: _propTypes2.default.func,
    onExited: _propTypes2.default.func
  }, _temp;
};

module.exports = exports['default'];