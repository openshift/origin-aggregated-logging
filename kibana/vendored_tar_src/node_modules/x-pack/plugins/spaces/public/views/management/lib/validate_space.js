"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
const i18n_1 = require("@kbn/i18n");
const is_reserved_space_1 = require("../../../../common/is_reserved_space");
const space_identifier_utils_1 = require("./space_identifier_utils");
class SpaceValidator {
    constructor(options = {}) {
        this.shouldValidate = options.shouldValidate || false;
    }
    enableValidation() {
        this.shouldValidate = true;
    }
    disableValidation() {
        this.shouldValidate = false;
    }
    validateSpaceName(space) {
        if (!this.shouldValidate) {
            return valid();
        }
        if (!space.name || !space.name.trim()) {
            return invalid(i18n_1.i18n.translate('xpack.spaces.management.validateSpace.requiredNameErrorMessage', {
                defaultMessage: 'Name is required.',
            }));
        }
        if (space.name.length > 1024) {
            return invalid(i18n_1.i18n.translate('xpack.spaces.management.validateSpace.nameMaxLengthErrorMessage', {
                defaultMessage: 'Name must not exceed 1024 characters.',
            }));
        }
        return valid();
    }
    validateSpaceDescription(space) {
        if (!this.shouldValidate) {
            return valid();
        }
        if (space.description && space.description.length > 2000) {
            return invalid(i18n_1.i18n.translate('xpack.spaces.management.validateSpace.describeMaxLengthErrorMessage', {
                defaultMessage: 'Description must not exceed 2000 characters.',
            }));
        }
        return valid();
    }
    validateURLIdentifier(space) {
        if (!this.shouldValidate) {
            return valid();
        }
        if (is_reserved_space_1.isReservedSpace(space)) {
            return valid();
        }
        if (!space.id) {
            return invalid(i18n_1.i18n.translate('xpack.spaces.management.validateSpace.urlIdentifierRequiredErrorMessage', {
                defaultMessage: 'URL identifier is required.',
            }));
        }
        if (!space_identifier_utils_1.isValidSpaceIdentifier(space.id)) {
            return invalid(i18n_1.i18n.translate('xpack.spaces.management.validateSpace.urlIdentifierAllowedCharactersErrorMessage', {
                defaultMessage: 'URL identifier can only contain a-z, 0-9, and the characters "_" and "-".',
            }));
        }
        return valid();
    }
    validateForSave(space) {
        const { isInvalid: isNameInvalid } = this.validateSpaceName(space);
        const { isInvalid: isDescriptionInvalid } = this.validateSpaceDescription(space);
        const { isInvalid: isIdentifierInvalid } = this.validateURLIdentifier(space);
        if (isNameInvalid || isDescriptionInvalid || isIdentifierInvalid) {
            return invalid();
        }
        return valid();
    }
}
exports.SpaceValidator = SpaceValidator;
function invalid(error = '') {
    return {
        isInvalid: true,
        error,
    };
}
function valid() {
    return {
        isInvalid: false,
    };
}
