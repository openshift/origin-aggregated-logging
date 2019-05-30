"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const eui_1 = require("@elastic/eui");
const react_1 = require("@kbn/i18n/react");
const react_2 = tslib_1.__importStar(require("react"));
const constants_1 = require("../../../../common/constants");
const components_1 = require("../../../components");
class SpacesMenuUI extends react_2.Component {
    constructor() {
        super(...arguments);
        this.state = {
            searchTerm: '',
            allowSpacesListFocus: false,
        };
        this.getVisibleSpaces = (searchTerm) => {
            const { spaces } = this.props;
            let filteredSpaces = spaces;
            if (searchTerm) {
                filteredSpaces = spaces.filter(space => {
                    const { name, description = '' } = space;
                    return (name.toLowerCase().indexOf(searchTerm) >= 0 ||
                        description.toLowerCase().indexOf(searchTerm) >= 0);
                });
            }
            return filteredSpaces;
        };
        this.renderSpacesListPanel = (items, searchTerm) => {
            if (items.length === 0) {
                return (react_2.default.createElement(eui_1.EuiText, { color: "subdued", className: "eui-textCenter" },
                    react_2.default.createElement(react_1.FormattedMessage, { id: "xpack.spaces.navControl.spacesMenu.noSpacesFoundTitle", defaultMessage: " no spaces found " })));
            }
            return (react_2.default.createElement(eui_1.EuiContextMenuPanel, { key: `spcMenuList`, "data-search-term": searchTerm, className: "spcMenu__spacesList", hasFocus: this.state.allowSpacesListFocus, initialFocusedItemIndex: this.state.allowSpacesListFocus ? 0 : undefined, items: items }));
        };
        this.renderSearchField = () => {
            const { intl } = this.props;
            return (react_2.default.createElement("div", { key: "manageSpacesSearchField", className: "spcMenu__searchFieldWrapper" },
                react_2.default.createElement(eui_1.EuiFieldSearch, { placeholder: intl.formatMessage({
                        id: 'xpack.spaces.navControl.spacesMenu.findSpacePlaceholder',
                        defaultMessage: 'Find a space',
                    }), incremental: true, 
                    // FIXME needs updated typedef
                    // @ts-ignore
                    onSearch: this.onSearch, onKeyDown: this.onSearchKeyDown, onFocus: this.onSearchFocus, compressed: true })));
        };
        this.onSearchKeyDown = (e) => {
            //  9: tab
            // 13: enter
            // 40: arrow-down
            const focusableKeyCodes = [9, 13, 40];
            const keyCode = e.keyCode;
            if (focusableKeyCodes.includes(keyCode)) {
                // Allows the spaces list panel to recieve focus. This enables keyboard and screen reader navigation
                this.setState({
                    allowSpacesListFocus: true,
                });
            }
        };
        this.onSearchFocus = () => {
            this.setState({
                allowSpacesListFocus: false,
            });
        };
        this.renderManageButton = () => {
            return (react_2.default.createElement(components_1.ManageSpacesButton, { key: "manageSpacesButton", className: "spcMenu__manageButton", size: "s", userProfile: this.props.userProfile, onClick: this.props.onManageSpacesClick }));
        };
        this.onSearch = (searchTerm) => {
            this.setState({
                searchTerm: searchTerm.trim().toLowerCase(),
            });
        };
        this.renderSpaceMenuItem = (space) => {
            const icon = react_2.default.createElement(components_1.SpaceAvatar, { space: space, size: 's' });
            return (react_2.default.createElement(eui_1.EuiContextMenuItem, { key: space.id, icon: icon, onClick: this.props.onSelectSpace.bind(this, space), toolTipTitle: space.description && space.name, toolTipContent: space.description }, space.name));
        };
    }
    render() {
        const { intl } = this.props;
        const { searchTerm } = this.state;
        const items = this.getVisibleSpaces(searchTerm).map(this.renderSpaceMenuItem);
        const panelProps = {
            className: 'spcMenu',
            title: intl.formatMessage({
                id: 'xpack.spaces.navControl.spacesMenu.changeCurrentSpaceTitle',
                defaultMessage: 'Change current space',
            }),
            watchedItemProps: ['data-search-term'],
        };
        if (this.props.spaces.length >= constants_1.SPACE_SEARCH_COUNT_THRESHOLD) {
            return (react_2.default.createElement(eui_1.EuiContextMenuPanel, Object.assign({}, panelProps),
                this.renderSearchField(),
                this.renderSpacesListPanel(items, searchTerm),
                this.renderManageButton()));
        }
        items.push(this.renderManageButton());
        return react_2.default.createElement(eui_1.EuiContextMenuPanel, Object.assign({}, panelProps, { items: items }));
    }
}
exports.SpacesMenu = react_1.injectI18n(SpacesMenuUI);
