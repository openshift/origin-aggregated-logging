"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const eui_1 = require("@elastic/eui");
const react_1 = tslib_1.__importStar(require("react"));
const components_1 = require("../../components");
const spaces_description_1 = require("./components/spaces_description");
const spaces_menu_1 = require("./components/spaces_menu");
class NavControlPopover extends react_1.Component {
    constructor(props) {
        super(props);
        this.getActiveSpaceButton = () => {
            const { activeSpace } = this.state;
            if (!activeSpace) {
                return this.getButton(react_1.default.createElement(eui_1.EuiAvatar, { size: 's', className: 'spaceNavGraphic', name: 'error' }), 'error');
            }
            return this.getButton(react_1.default.createElement(components_1.SpaceAvatar, { space: activeSpace, size: 's', className: 'spaceNavGraphic' }), activeSpace.name);
        };
        this.getButton = (linkIcon, linkTitle) => {
            const Button = this.props.buttonClass;
            return (react_1.default.createElement(Button, { linkTitle: linkTitle, linkIcon: linkIcon, toggleSpaceSelector: this.toggleSpaceSelector, spaceSelectorShown: this.state.showSpaceSelector }));
        };
        this.toggleSpaceSelector = () => {
            const isOpening = !this.state.showSpaceSelector;
            if (isOpening) {
                this.loadSpaces();
            }
            this.setState({
                showSpaceSelector: !this.state.showSpaceSelector,
            });
        };
        this.closeSpaceSelector = () => {
            this.setState({
                showSpaceSelector: false,
            });
        };
        this.onSelectSpace = (space) => {
            this.props.spacesManager.changeSelectedSpace(space);
        };
        this.state = {
            showSpaceSelector: false,
            loading: false,
            activeSpace: props.activeSpace.space,
            spaces: [],
        };
    }
    componentDidMount() {
        this.loadSpaces();
        if (this.props.spacesManager) {
            this.props.spacesManager.on('request_refresh', () => {
                this.loadSpaces();
            });
        }
    }
    render() {
        const button = this.getActiveSpaceButton();
        if (!button) {
            return null;
        }
        let element;
        if (this.state.spaces.length < 2) {
            element = (react_1.default.createElement(spaces_description_1.SpacesDescription, { userProfile: this.props.userProfile, onManageSpacesClick: this.toggleSpaceSelector }));
        }
        else {
            element = (react_1.default.createElement(spaces_menu_1.SpacesMenu, { spaces: this.state.spaces, onSelectSpace: this.onSelectSpace, userProfile: this.props.userProfile, onManageSpacesClick: this.toggleSpaceSelector }));
        }
        return (react_1.default.createElement(eui_1.EuiPopover, { id: 'spcMenuPopover', "data-test-subj": `spacesNavSelector`, button: button, isOpen: this.state.showSpaceSelector, closePopover: this.closeSpaceSelector, anchorPosition: this.props.anchorPosition, panelPaddingSize: "none", 
            // @ts-ignore
            repositionOnScroll: true, withTitle: this.props.anchorPosition.includes('down'), ownFocus: true }, element));
    }
    async loadSpaces() {
        const { spacesManager, activeSpace } = this.props;
        this.setState({
            loading: true,
        });
        const spaces = await spacesManager.getSpaces();
        // Update the active space definition, if it changed since the last load operation
        let activeSpaceEntry = activeSpace.space;
        if (activeSpace.valid) {
            activeSpaceEntry = spaces.find(space => space.id === this.props.activeSpace.space.id) || null;
        }
        this.setState({
            spaces,
            activeSpace: activeSpaceEntry,
            loading: false,
        });
    }
}
exports.NavControlPopover = NavControlPopover;
