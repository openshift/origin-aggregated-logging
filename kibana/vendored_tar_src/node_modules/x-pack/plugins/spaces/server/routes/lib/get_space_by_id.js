"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const convert_saved_object_to_space_1 = require("./convert_saved_object_to_space");
async function getSpaceById(client, spaceId, errors) {
    try {
        const existingSpace = await client.get(spaceId);
        return convert_saved_object_to_space_1.convertSavedObjectToSpace(existingSpace);
    }
    catch (error) {
        if (errors.isNotFoundError(error)) {
            return null;
        }
        throw error;
    }
}
exports.getSpaceById = getSpaceById;
