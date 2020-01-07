"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const querystring_1 = require("querystring");
const react_1 = tslib_1.__importDefault(require("react"));
const react_router_dom_1 = require("react-router-dom");
class WithURLStateComponent extends react_1.default.Component {
    constructor() {
        super(...arguments);
        this.historyListener = null;
        this.setURLState = async (state) => {
            let newState;
            const pastState = this.URLState;
            if (typeof state === 'function') {
                newState = await state(pastState);
            }
            else {
                newState = state;
            }
            const search = querystring_1.stringify({
                ...pastState,
                ...newState,
            });
            const newLocation = {
                ...this.props.history.location,
                search,
            };
            this.props.history.replace(newLocation);
            this.forceUpdate();
        };
        this.goTo = (path) => {
            this.props.history.push({
                pathname: path,
                search: this.props.history.location.search,
            });
        };
    }
    get URLState() {
        // slice because parse does not account for the initial ? in the search string
        return querystring_1.parse(decodeURIComponent(this.props.history.location.search).substring(1));
    }
    componentWillUnmount() {
        if (this.historyListener) {
            this.historyListener();
        }
    }
    render() {
        return this.props.children({
            goTo: this.goTo,
            setUrlState: this.setURLState,
            urlState: this.URLState || {},
        });
    }
}
exports.WithURLStateComponent = WithURLStateComponent;
exports.WithURLState = react_router_dom_1.withRouter(WithURLStateComponent);
function withUrlState(UnwrappedComponent) {
    return (origProps) => {
        return (react_1.default.createElement(exports.WithURLState, null, (URLProps) => react_1.default.createElement(UnwrappedComponent, Object.assign({}, URLProps, origProps))));
    };
}
exports.withUrlState = withUrlState;
