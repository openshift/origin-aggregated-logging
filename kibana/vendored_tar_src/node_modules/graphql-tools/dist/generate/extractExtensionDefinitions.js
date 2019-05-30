"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var newExtensionDefinitionKind = 'ObjectTypeExtension';
var interfaceExtensionDefinitionKind = 'InterfaceTypeExtension';
function extractExtensionDefinitions(ast) {
    var extensionDefs = ast.definitions.filter(function (def) {
        return def.kind === newExtensionDefinitionKind ||
            def.kind === interfaceExtensionDefinitionKind;
    });
    return Object.assign({}, ast, {
        definitions: extensionDefs,
    });
}
exports.default = extractExtensionDefinitions;
//# sourceMappingURL=extractExtensionDefinitions.js.map