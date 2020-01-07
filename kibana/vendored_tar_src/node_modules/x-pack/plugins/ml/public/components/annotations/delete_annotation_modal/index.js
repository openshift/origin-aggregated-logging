"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const prop_types_1 = tslib_1.__importDefault(require("prop-types"));
const react_1 = tslib_1.__importStar(require("react"));
const eui_1 = require("@elastic/eui");
const react_2 = require("@kbn/i18n/react");
exports.DeleteAnnotationModal = ({ cancelAction, deleteAction, isVisible, }) => {
    return (react_1.default.createElement(react_1.Fragment, null, isVisible === true && (react_1.default.createElement(eui_1.EuiOverlayMask, null,
        react_1.default.createElement(eui_1.EuiConfirmModal, { title: react_1.default.createElement(react_2.FormattedMessage, { id: "xpack.ml.timeSeriesExplorer.deleteAnnotationModal.deleteAnnotationTitle", defaultMessage: "Delete this annotation?" }), onCancel: cancelAction, onConfirm: deleteAction, cancelButtonText: react_1.default.createElement(react_2.FormattedMessage, { id: "xpack.ml.timeSeriesExplorer.deleteAnnotationModal.cancelButtonLabel", defaultMessage: "Cancel" }), confirmButtonText: react_1.default.createElement(react_2.FormattedMessage, { id: "xpack.ml.timeSeriesExplorer.deleteAnnotationModal.deleteButtonLabel", defaultMessage: "Delete" }), buttonColor: "danger", defaultFocusedButton: eui_1.EUI_MODAL_CONFIRM_BUTTON, className: "eui-textBreakWord" })))));
};
exports.DeleteAnnotationModal.propTypes = {
    cancelAction: prop_types_1.default.func.isRequired,
    deleteAction: prop_types_1.default.func.isRequired,
    isVisible: prop_types_1.default.bool.isRequired,
};
