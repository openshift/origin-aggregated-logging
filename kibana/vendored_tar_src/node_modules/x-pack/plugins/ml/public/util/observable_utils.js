"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const react_1 = tslib_1.__importStar(require("react"));
// Sets up a ObservableComponent which subscribes to given observable updates and
// and passes them on as prop values to the given WrappedComponent.
// This give us the benefit of abstracting away the need to set up subscribers and callbacks,
// and the passed down props can be used in pure/functional components without
// the need for their own state management.
function injectObservablesAsProps(observables, WrappedComponent) {
    const observableKeys = Object.keys(observables);
    class ObservableComponent extends react_1.Component {
        constructor() {
            super(...arguments);
            this.state = observableKeys.reduce((reducedState, key) => {
                reducedState[key] = observables[key].value;
                return reducedState;
            }, {});
            this.subscriptions = {};
        }
        componentDidMount() {
            observableKeys.forEach(k => {
                this.subscriptions[k] = observables[k].subscribe(v => this.setState({ [k]: v }));
            });
        }
        componentWillUnmount() {
            Object.keys(this.subscriptions).forEach((key) => this.subscriptions[key].unsubscribe());
        }
        render() {
            return (react_1.default.createElement(WrappedComponent, Object.assign({}, this.props, this.state), this.props.children));
        }
    }
    return ObservableComponent;
}
exports.injectObservablesAsProps = injectObservablesAsProps;
