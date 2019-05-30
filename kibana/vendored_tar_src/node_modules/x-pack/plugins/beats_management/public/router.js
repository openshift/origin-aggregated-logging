"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const lodash_1 = require("lodash");
const react_1 = tslib_1.__importStar(require("react"));
const react_router_dom_1 = require("react-router-dom");
const loading_1 = require("./components/loading");
const child_routes_1 = require("./components/navigation/child_routes");
const with_url_state_1 = require("./containers/with_url_state");
const index_1 = require("./pages/index");
class AppRouter extends react_1.Component {
    constructor(props) {
        super(props);
        this.state = {
            loading: true,
        };
    }
    async componentWillMount() {
        if (this.state.loading === true) {
            try {
                await this.props.beatsContainer.reload();
                await this.props.tagsContainer.reload();
            }
            catch (e) {
                // TODO in a furture version we will better manage this "error" in a returned arg
            }
            this.setState({
                loading: false,
            });
        }
    }
    render() {
        if (this.state.loading === true) {
            return react_1.default.createElement(loading_1.Loading, null);
        }
        const countOfEverything = this.props.beatsContainer.state.list.length + this.props.tagsContainer.state.list.length;
        return (react_1.default.createElement(react_1.default.Fragment, null,
            react_1.default.createElement(react_router_dom_1.Switch, null,
                lodash_1.get(this.props.libs.framework.info, 'license.expired', true) && (react_1.default.createElement(react_router_dom_1.Route, { render: props => !props.location.pathname.includes('/error') ? (react_1.default.createElement(react_router_dom_1.Redirect, { to: "/error/invalid_license" })) : null })),
                !lodash_1.get(this.props.libs.framework.info, 'security.enabled', true) && (react_1.default.createElement(react_router_dom_1.Route, { render: props => !props.location.pathname.includes('/error') ? (react_1.default.createElement(react_router_dom_1.Redirect, { to: "/error/enforce_security" })) : null })),
                !this.props.libs.framework.currentUserHasOneOfRoles(['beats_admin'].concat(this.props.libs.framework.info.settings.defaultUserRoles)) && (react_1.default.createElement(react_router_dom_1.Route, { render: props => !props.location.pathname.includes('/error') ? (react_1.default.createElement(react_router_dom_1.Redirect, { to: "/error/no_access" })) : null })),
                countOfEverything === 0 && (react_1.default.createElement(react_router_dom_1.Route, { render: props => !props.location.pathname.includes('/walkthrough') ? (react_1.default.createElement(react_router_dom_1.Redirect, { to: "/walkthrough/initial" })) : null })),
                react_1.default.createElement(react_router_dom_1.Route, { path: "/", exact: true, render: () => react_1.default.createElement(react_router_dom_1.Redirect, { to: "/overview/enrolled_beats" }) })),
            react_1.default.createElement(with_url_state_1.WithURLState, null, (URLProps) => (react_1.default.createElement(child_routes_1.ChildRoutes, Object.assign({ routes: index_1.routeMap }, URLProps, {
                libs: this.props.libs,
                containers: {
                    beats: this.props.beatsContainer,
                    tags: this.props.tagsContainer,
                },
            }))))));
    }
}
exports.AppRouter = AppRouter;
