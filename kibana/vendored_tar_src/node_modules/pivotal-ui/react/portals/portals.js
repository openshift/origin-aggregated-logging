/*(c) Copyright 2015 Pivotal Software, Inc. All Rights Reserved.*/
'use strict';

exports.__esModule = true;
exports.PortalDestination = exports.PortalSource = exports.reset = undefined;

var _classCallCheck2 = require('babel-runtime/helpers/classCallCheck');

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _possibleConstructorReturn2 = require('babel-runtime/helpers/possibleConstructorReturn');

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = require('babel-runtime/helpers/inherits');

var _inherits3 = _interopRequireDefault(_inherits2);

var _events = require('events');

var _react = require('react');

var _react2 = _interopRequireDefault(_react);

var _propTypes = require('prop-types');

var _propTypes2 = _interopRequireDefault(_propTypes);

var _reactDom = require('react-dom');

var _reactDom2 = _interopRequireDefault(_reactDom);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var destinationPortals = {};
var emitter = new _events.EventEmitter();

var createRoot = function createRoot(reactElement) {
  var destination = document.createElement('div');
  _reactDom2.default.findDOMNode(reactElement).appendChild(destination);
  return destination;
};

var reset = exports.reset = function reset() {
  emitter.removeAllListeners();
  destinationPortals = {};
};

var PortalSource = exports.PortalSource = function (_React$PureComponent) {
  (0, _inherits3.default)(PortalSource, _React$PureComponent);

  function PortalSource(props, context) {
    (0, _classCallCheck3.default)(this, PortalSource);

    var _this = (0, _possibleConstructorReturn3.default)(this, _React$PureComponent.call(this, props, context));

    _this.setDestination = function () {
      var destination = _this.state.destination;

      var destinationPortal = destinationPortals[_this.props.name];
      if (destination && destination.portal === destinationPortal) return;
      _this.setState({ destination: destinationPortal && { portal: destinationPortal, root: createRoot(destinationPortal) } }, _this.componentDidUpdate);
    };

    _this.state = { destination: null };
    return _this;
  }

  PortalSource.prototype.componentDidMount = function componentDidMount() {
    emitter.on('destination', this.setDestination);
    this.setDestination();
    this.componentDidUpdate();
  };

  PortalSource.prototype.componentDidUpdate = function componentDidUpdate() {
    var _ref = this.state.destination || {},
        root = _ref.root;

    if (root) _reactDom2.default.render(_react2.default.createElement(
      'div',
      null,
      this.props.children
    ), root);
  };

  PortalSource.prototype.componentWillUnmount = function componentWillUnmount() {
    emitter.removeListener('destination', this.setDestination);

    var _ref2 = this.state.destination || {},
        root = _ref2.root;

    if (root) {
      root.parentNode.removeChild(root);
    }
  };

  PortalSource.prototype.render = function render() {
    return null;
  };

  return PortalSource;
}(_react2.default.PureComponent);

PortalSource.propTypes = {
  name: _propTypes2.default.string.isRequired
};

var PortalDestination = exports.PortalDestination = function (_React$PureComponent2) {
  (0, _inherits3.default)(PortalDestination, _React$PureComponent2);

  function PortalDestination() {
    (0, _classCallCheck3.default)(this, PortalDestination);
    return (0, _possibleConstructorReturn3.default)(this, _React$PureComponent2.apply(this, arguments));
  }

  PortalDestination.prototype.componentDidMount = function componentDidMount() {
    var name = this.props.name;

    if (name in destinationPortals) {
      console.warn('Warning: Multiple destination portals with the same name "' + name + '" detected.');
    }

    destinationPortals[name] = this;
    emitter.emit('destination', this);
  };

  PortalDestination.prototype.componentWillUnmount = function componentWillUnmount() {
    delete destinationPortals[this.props.name];
    emitter.emit('destination', this);
  };

  PortalDestination.prototype.render = function render() {
    return _react2.default.createElement('div', null);
  };

  return PortalDestination;
}(_react2.default.PureComponent);

PortalDestination.propTypes = {
  name: _propTypes2.default.string.isRequired
};