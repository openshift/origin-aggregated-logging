"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const React = tslib_1.__importStar(require("react"));
class MeasurableItemView extends React.PureComponent {
    constructor() {
        super(...arguments);
        this.childRef = React.createRef();
        this.getOffsetRect = () => {
            const currentElement = this.childRef.current;
            if (currentElement === null) {
                return null;
            }
            return {
                height: currentElement.offsetHeight,
                left: currentElement.offsetLeft,
                top: currentElement.offsetTop,
                width: currentElement.offsetWidth,
            };
        };
    }
    componentDidMount() {
        this.props.register(this.props.registrationKey, this);
    }
    componentWillUnmount() {
        this.props.register(this.props.registrationKey, null);
    }
    componentDidUpdate(prevProps) {
        if (prevProps.registrationKey !== this.props.registrationKey) {
            this.props.register(prevProps.registrationKey, null);
            this.props.register(this.props.registrationKey, this);
        }
    }
    render() {
        return this.props.children(this.childRef);
    }
}
exports.MeasurableItemView = MeasurableItemView;
