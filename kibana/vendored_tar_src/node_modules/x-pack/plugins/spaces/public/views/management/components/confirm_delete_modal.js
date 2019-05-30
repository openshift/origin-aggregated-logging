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
class ConfirmDeleteModalUI extends react_2.Component {
    constructor() {
        super(...arguments);
        this.state = {
            confirmSpaceName: '',
            error: null,
            deleteInProgress: false,
        };
        this.onSpaceNameChange = (e) => {
            if (typeof this.state.error === 'boolean') {
                this.setState({
                    confirmSpaceName: e.target.value,
                    error: e.target.value !== this.props.space.name,
                });
            }
            else {
                this.setState({
                    confirmSpaceName: e.target.value,
                });
            }
        };
        this.onConfirm = async () => {
            if (this.state.confirmSpaceName === this.props.space.name) {
                const needsRedirect = isDeletingCurrentSpace(this.props.space, this.props.spacesNavState);
                const spacesManager = this.props.spacesManager;
                this.setState({
                    deleteInProgress: true,
                });
                await this.props.onConfirm();
                this.setState({
                    deleteInProgress: false,
                });
                if (needsRedirect) {
                    spacesManager.redirectToSpaceSelector();
                }
            }
            else {
                this.setState({
                    error: true,
                });
            }
        };
    }
    render() {
        const { space, spacesNavState, onCancel, intl } = this.props;
        let warning = null;
        if (isDeletingCurrentSpace(space, spacesNavState)) {
            const name = (react_2.default.createElement("span", null,
                "(",
                react_2.default.createElement("strong", null, space.name),
                ")"));
            warning = (react_2.default.createElement(eui_1.EuiCallOut, { color: "warning" },
                react_2.default.createElement(eui_1.EuiText, null,
                    react_2.default.createElement(react_1.FormattedMessage, { id: "xpack.spaces.management.confirmDeleteModal.redirectAfterDeletingCurrentSpaceWarningMessage", defaultMessage: "You are about to delete your current space {name}. You will be redirected to choose a different space if you continue.", values: { name } }))));
        }
        // This is largely the same as the built-in EuiConfirmModal component, but we needed the ability
        // to disable the buttons since this could be a long-running operation
        return (react_2.default.createElement(eui_1.EuiOverlayMask, null,
            react_2.default.createElement(eui_1.EuiModal, { onClose: onCancel, className: 'spcConfirmDeleteModal' },
                react_2.default.createElement(eui_1.EuiModalHeader, null,
                    react_2.default.createElement(eui_1.EuiModalHeaderTitle, { "data-test-subj": "confirmModalTitleText" },
                        react_2.default.createElement(react_1.FormattedMessage, { id: "xpack.spaces.management.confirmDeleteModal.confirmDeleteSpaceButtonLabel", defaultMessage: "Delete space {spaceName}", values: {
                                spaceName: "'" + space.name + "'",
                            } }))),
                react_2.default.createElement(eui_1.EuiModalBody, null,
                    react_2.default.createElement(eui_1.EuiText, { "data-test-subj": "confirmModalBodyText" },
                        react_2.default.createElement("p", null,
                            react_2.default.createElement(react_1.FormattedMessage, { id: "xpack.spaces.management.confirmDeleteModal.deletingSpaceWarningMessage", defaultMessage: "Deleting a space permanently removes the space and {allContents}. You can't undo this action.", values: {
                                    allContents: (react_2.default.createElement("strong", null,
                                        react_2.default.createElement(react_1.FormattedMessage, { id: "xpack.spaces.management.confirmDeleteModal.allContentsText", defaultMessage: "all of its contents" }))),
                                } })),
                        react_2.default.createElement(eui_1.EuiFormRow, { label: intl.formatMessage({
                                id: 'xpack.spaces.management.confirmDeleteModal.confirmSpaceNameFormRowLabel',
                                defaultMessage: 'Confirm space name',
                            }), isInvalid: !!this.state.error, error: intl.formatMessage({
                                id: 'xpack.spaces.management.confirmDeleteModal.spaceNamesDoNoMatchErrorMessage',
                                defaultMessage: 'Space names do not match.',
                            }) },
                            react_2.default.createElement(eui_1.EuiFieldText, { value: this.state.confirmSpaceName, onChange: this.onSpaceNameChange, disabled: this.state.deleteInProgress })),
                        warning)),
                react_2.default.createElement(eui_1.EuiModalFooter, null,
                    react_2.default.createElement(eui_1.EuiButtonEmpty, { "data-test-subj": "confirmModalCancelButton", onClick: onCancel, isDisabled: this.state.deleteInProgress },
                        react_2.default.createElement(react_1.FormattedMessage, { id: "xpack.spaces.management.confirmDeleteModal.cancelButtonLabel", defaultMessage: "Cancel" })),
                    react_2.default.createElement(eui_1.EuiButton, { "data-test-subj": "confirmModalConfirmButton", onClick: this.onConfirm, fill: true, color: 'danger', isLoading: this.state.deleteInProgress },
                        react_2.default.createElement(react_1.FormattedMessage, { id: "xpack.spaces.management.confirmDeleteModal.deleteSpaceAndAllContentsButtonLabel", defaultMessage: " Delete space and all contents" }))))));
    }
}
function isDeletingCurrentSpace(space, spacesNavState) {
    return space.id === spacesNavState.getActiveSpace().id;
}
exports.ConfirmDeleteModal = react_1.injectI18n(ConfirmDeleteModalUI);
