"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var _1 = require(".");
var graphql_1 = require("graphql");
var _2 = require(".");
function addResolveFunctionsToSchema(options, legacyInputResolvers, legacyInputValidationOptions) {
    if (options instanceof graphql_1.GraphQLSchema) {
        console.warn('The addResolveFunctionsToSchema function takes named options now; see IAddResolveFunctionsToSchemaOptions');
        options = {
            schema: options,
            resolvers: legacyInputResolvers,
            resolverValidationOptions: legacyInputValidationOptions,
        };
    }
    var schema = options.schema, inputResolvers = options.resolvers, _a = options.resolverValidationOptions, resolverValidationOptions = _a === void 0 ? {} : _a, _b = options.inheritResolversFromInterfaces, inheritResolversFromInterfaces = _b === void 0 ? false : _b;
    var _c = resolverValidationOptions.allowResolversNotInSchema, allowResolversNotInSchema = _c === void 0 ? false : _c, requireResolversForResolveType = resolverValidationOptions.requireResolversForResolveType;
    var resolvers = inheritResolversFromInterfaces
        ? _2.extendResolversFromInterfaces(schema, inputResolvers)
        : inputResolvers;
    Object.keys(resolvers).forEach(function (typeName) {
        var resolverValue = resolvers[typeName];
        var resolverType = typeof resolverValue;
        if (resolverType !== 'object' && resolverType !== 'function') {
            throw new _1.SchemaError("\"" + typeName + "\" defined in resolvers, but has invalid value \"" + resolverValue + "\". A resolver's value " +
                "must be of type object or function.");
        }
        var type = schema.getType(typeName);
        if (!type && typeName !== '__schema') {
            if (allowResolversNotInSchema) {
                return;
            }
            throw new _1.SchemaError("\"" + typeName + "\" defined in resolvers, but not in schema");
        }
        Object.keys(resolverValue).forEach(function (fieldName) {
            if (fieldName.startsWith('__')) {
                // this is for isTypeOf and resolveType and all the other stuff.
                type[fieldName.substring(2)] = resolverValue[fieldName];
                return;
            }
            if (type instanceof graphql_1.GraphQLScalarType) {
                type[fieldName] = resolverValue[fieldName];
                return;
            }
            if (type instanceof graphql_1.GraphQLEnumType) {
                if (!type.getValue(fieldName)) {
                    if (allowResolversNotInSchema) {
                        return;
                    }
                    throw new _1.SchemaError(typeName + "." + fieldName + " was defined in resolvers, but enum is not in schema");
                }
                type.getValue(fieldName)['value'] = resolverValue[fieldName];
                return;
            }
            // object type
            var fields = getFieldsForType(type);
            if (!fields) {
                if (allowResolversNotInSchema) {
                    return;
                }
                throw new _1.SchemaError(typeName + " was defined in resolvers, but it's not an object");
            }
            if (!fields[fieldName]) {
                if (allowResolversNotInSchema) {
                    return;
                }
                throw new _1.SchemaError(typeName + "." + fieldName + " defined in resolvers, but not in schema");
            }
            var field = fields[fieldName];
            var fieldResolve = resolverValue[fieldName];
            if (typeof fieldResolve === 'function') {
                // for convenience. Allows shorter syntax in resolver definition file
                setFieldProperties(field, { resolve: fieldResolve });
            }
            else {
                if (typeof fieldResolve !== 'object') {
                    throw new _1.SchemaError("Resolver " + typeName + "." + fieldName + " must be object or function");
                }
                setFieldProperties(field, fieldResolve);
            }
        });
    });
    _2.checkForResolveTypeResolver(schema, requireResolversForResolveType);
}
function getFieldsForType(type) {
    if (type instanceof graphql_1.GraphQLObjectType ||
        type instanceof graphql_1.GraphQLInterfaceType) {
        return type.getFields();
    }
    else {
        return undefined;
    }
}
function setFieldProperties(field, propertiesObj) {
    Object.keys(propertiesObj).forEach(function (propertyName) {
        field[propertyName] = propertiesObj[propertyName];
    });
}
exports.default = addResolveFunctionsToSchema;
//# sourceMappingURL=addResolveFunctionsToSchema.js.map