/*(c) Copyright 2015 Pivotal Software, Inc. All Rights Reserved.*/
'use strict';

exports.__esModule = true;

var _keys = require('babel-runtime/core-js/object/keys');

var _keys2 = _interopRequireDefault(_keys);

var _extends2 = require('babel-runtime/helpers/extends');

var _extends3 = _interopRequireDefault(_extends2);

var _objectWithoutProperties2 = require('babel-runtime/helpers/objectWithoutProperties');

var _objectWithoutProperties3 = _interopRequireDefault(_objectWithoutProperties2);

var _classCallCheck2 = require('babel-runtime/helpers/classCallCheck');

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = require('babel-runtime/helpers/createClass');

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = require('babel-runtime/helpers/possibleConstructorReturn');

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = require('babel-runtime/helpers/inherits');

var _inherits3 = _interopRequireDefault(_inherits2);

var _react = require('react');

var _react2 = _interopRequireDefault(_react);

var _propTypes = require('prop-types');

var _propTypes2 = _interopRequireDefault(_propTypes);

var _reactDom = require('react-dom');

var _reactDom2 = _interopRequireDefault(_reactDom);

var _tether = require('tether');

var _tether2 = _interopRequireDefault(_tether);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

if (!_tether2.default) {
  console.error('It looks like Tether has not been included. Please load this dependency first https://github.com/HubSpot/tether');
}

var renderElementToPropTypes = [_propTypes2.default.string, _propTypes2.default.shape({
  appendChild: _propTypes2.default.func.isRequired
})];

var childrenPropType = function childrenPropType(_ref, propName, componentName) {
  var children = _ref.children;

  var childCount = _react.Children.count(children);
  if (childCount <= 0) {
    return new Error(componentName + ' expects at least one child to use as the target element.');
  } else if (childCount > 2) {
    return new Error('Only a max of two children allowed in ' + componentName + '.');
  }
};

var attachmentPositions = ['auto auto', 'top left', 'top center', 'top right', 'middle left', 'middle center', 'middle right', 'bottom left', 'bottom center', 'bottom right'];

var TetherComponent = function (_Component) {
  (0, _inherits3.default)(TetherComponent, _Component);

  function TetherComponent() {
    var _temp, _this, _ret;

    (0, _classCallCheck3.default)(this, TetherComponent);

    for (var _len = arguments.length, args = Array(_len), _key = 0; _key < _len; _key++) {
      args[_key] = arguments[_key];
    }

    return _ret = (_temp = (_this = (0, _possibleConstructorReturn3.default)(this, _Component.call.apply(_Component, [this].concat(args))), _this), _this._targetNode = null, _this._elementParentNode = null, _this._tether = false, _temp), (0, _possibleConstructorReturn3.default)(_this, _ret);
  }

  TetherComponent.prototype.componentDidMount = function componentDidMount() {
    this._targetNode = _reactDom2.default.findDOMNode(this);
    this._update();
  };

  TetherComponent.prototype.componentDidUpdate = function componentDidUpdate(prevProps) {
    this._targetNode = _reactDom2.default.findDOMNode(this);
    this._update();
  };

  TetherComponent.prototype.componentWillUnmount = function componentWillUnmount() {
    this._destroy();
  };

  TetherComponent.prototype.getTetherInstance = function getTetherInstance() {
    return this._tether;
  };

  TetherComponent.prototype.disable = function disable() {
    this._tether.disable();
  };

  TetherComponent.prototype.enable = function enable() {
    this._tether.enable();
  };

  TetherComponent.prototype.on = function on(event, handler, ctx) {
    this._tether.on(event, handler, ctx);
  };

  TetherComponent.prototype.once = function once(event, handler, ctx) {
    this._tether.once(event, handler, ctx);
  };

  TetherComponent.prototype.off = function off(event, handler) {
    this._tether.off(event, handler);
  };

  TetherComponent.prototype.position = function position() {
    this._tether.position();
  };

  TetherComponent.prototype._registerEventListeners = function _registerEventListeners() {
    var _this2 = this,
        _arguments = arguments;

    this.on('update', function () {
      return _this2.props.onUpdate && _this2.props.onUpdate.apply(_this2, _arguments);
    });

    this.on('repositioned', function () {
      return _this2.props.onRepositioned && _this2.props.onRepositioned.apply(_this2, _arguments);
    });
  };

  TetherComponent.prototype._destroy = function _destroy() {
    if (this._elementParentNode) {
      _reactDom2.default.unmountComponentAtNode(this._elementParentNode);
      this._elementParentNode.parentNode.removeChild(this._elementParentNode);
    }

    if (this._tether) {
      this._tether.destroy();
    }

    this._elementParentNode = null;
    this._tether = null;
  };

  TetherComponent.prototype._update = function _update() {
    var _this3 = this;

    var _props = this.props,
        children = _props.children,
        renderElementTag = _props.renderElementTag;

    var elementComponent = _react.Children.toArray(children)[1];

    // if no element component provided, bail out
    if (!elementComponent) {
      // destroy Tether element if it has been created
      if (this._tether) {
        this._destroy();
      }
      return;
    }

    // create element node container if it hasn't been yet
    if (!this._elementParentNode) {
      // create a node that we can stick our content Component in
      this._elementParentNode = document.createElement(renderElementTag);

      // append node to the render node
      this._renderNode.appendChild(this._elementParentNode);
    }

    // render element component into the DOM
    _reactDom2.default.unstable_renderSubtreeIntoContainer(this, elementComponent, this._elementParentNode, function () {
      // if we're not destroyed, update Tether once the subtree has finished rendering
      if (_this3._elementParentNode) {
        _this3._updateTether();
      }
    });
  };

  TetherComponent.prototype._updateTether = function _updateTether() {
    var _this4 = this;

    var _props2 = this.props,
        children = _props2.children,
        renderElementTag = _props2.renderElementTag,
        renderElementTo = _props2.renderElementTo,
        id = _props2.id,
        className = _props2.className,
        style = _props2.style,
        options = (0, _objectWithoutProperties3.default)(_props2, ['children', 'renderElementTag', 'renderElementTo', 'id', 'className', 'style']);

    var tetherOptions = (0, _extends3.default)({
      target: this._targetNode,
      element: this._elementParentNode
    }, options);

    if (id) {
      this._elementParentNode.id = id;
    }

    if (className) {
      this._elementParentNode.className = className;
    }

    if (style) {
      (0, _keys2.default)(style).forEach(function (key) {
        _this4._elementParentNode.style[key] = style[key];
      });
    }

    if (!this._tether) {
      this._tether = new _tether2.default(tetherOptions);
      this._registerEventListeners();
    } else {
      this._tether.setOptions(tetherOptions);
    }

    this._tether.position();
  };

  TetherComponent.prototype.render = function render() {
    return _react.Children.toArray(this.props.children)[0];
  };

  (0, _createClass3.default)(TetherComponent, [{
    key: '_renderNode',
    get: function get() {
      var renderElementTo = this.props.renderElementTo;

      if (typeof renderElementTo === 'string') {
        return document.querySelector(renderElementTo);
      } else {
        return renderElementTo || document.body;
      }
    }
  }]);
  return TetherComponent;
}(_react.Component);

TetherComponent.propTypes = {
  renderElementTag: _propTypes2.default.string,
  renderElementTo: _propTypes2.default.oneOfType(renderElementToPropTypes),
  attachment: _propTypes2.default.oneOf(attachmentPositions).isRequired,
  targetAttachment: _propTypes2.default.oneOf(attachmentPositions),
  offset: _propTypes2.default.string,
  targetOffset: _propTypes2.default.string,
  targetModifier: _propTypes2.default.string,
  enabled: _propTypes2.default.bool,
  classes: _propTypes2.default.object,
  classPrefix: _propTypes2.default.string,
  optimizations: _propTypes2.default.object,
  constraints: _propTypes2.default.array,
  id: _propTypes2.default.string,
  className: _propTypes2.default.string,
  style: _propTypes2.default.object,
  onUpdate: _propTypes2.default.func,
  onRepositioned: _propTypes2.default.func,
  children: childrenPropType
};
TetherComponent.defaultProps = {
  renderElementTag: 'div',
  renderElementTo: null
};
exports.default = TetherComponent;
module.exports = exports['default'];