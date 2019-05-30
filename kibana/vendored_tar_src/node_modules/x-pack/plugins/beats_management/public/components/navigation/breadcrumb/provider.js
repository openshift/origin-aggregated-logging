"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
const react_1 = tslib_1.__importStar(require("react"));
const chrome_1 = tslib_1.__importDefault(require("ui/chrome"));
const context_1 = require("./context");
class BreadcrumbProvider extends react_1.Component {
    constructor() {
        super(...arguments);
        this.state = {
            breadcrumbs: [],
        };
        this.addCrumb = (breadcrumb, parents) => {
            this.setState(({ breadcrumbs: prevCrumbs }) => ({
                breadcrumbs: [
                    ...prevCrumbs,
                    {
                        href: breadcrumb.href,
                        breadcrumb,
                        parents,
                    },
                ],
            }));
        };
        this.removeCrumb = (crumbToRemove) => {
            this.setState(({ breadcrumbs: prevCrumbs }) => {
                const breadcrumbs = prevCrumbs.filter(prevCrumb => {
                    const { href } = prevCrumb;
                    return !(crumbToRemove.href === href);
                });
                return { breadcrumbs };
            });
        };
    }
    render() {
        const { breadcrumbs } = this.state;
        const context = {
            breadcrumbs: breadcrumbs.reduce((crumbs, crumbStorageItem) => {
                if (crumbStorageItem.parents) {
                    crumbs = crumbs.concat(crumbStorageItem.parents);
                }
                crumbs.push(crumbStorageItem.breadcrumb);
                return crumbs;
            }, []),
            addCrumb: this.addCrumb,
            removeCrumb: this.removeCrumb,
        };
        if (this.props.useGlobalBreadcrumbs) {
            chrome_1.default.breadcrumbs.set(context.breadcrumbs);
        }
        return react_1.default.createElement(context_1.Provider, { value: context }, this.props.children);
    }
}
exports.BreadcrumbProvider = BreadcrumbProvider;
