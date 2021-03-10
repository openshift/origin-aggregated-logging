import { uiModules } from 'ui/modules';
import { isEmpty } from 'lodash';
import client from './client';

/**
 * Role mappings API client service.
 */
uiModules.get('apps/opendistro_security/configuration', [])
    .service('backendRoles', function (backendAPI, Promise, $http) {

        const RESOURCE = 'roles';

        this.title = {
            singular: 'role',
            plural: 'roles'
        };

        this.newLabel = "Role name";

        this.list = () => {
            return backendAPI.list(RESOURCE);
        };

        this.listSilent = () => {
            return backendAPI.listSilent(RESOURCE);
        };

        this.listAutocomplete = (names) => {
            return backendAPI.listAutocomplete(names);
        };

        this.get = (id) => {
            return backendAPI.get(RESOURCE, id);
        };

        this.save = (rolename, data) => {
            sessionStorage.removeItem("rolesautocomplete");
            sessionStorage.removeItem("rolenames");
            var resourceCopy = JSON.parse(JSON.stringify(data));
            var data = this.preSave(resourceCopy);
            return backendAPI.save(RESOURCE, rolename, data);
        };

        this.delete = (id) => {
            sessionStorage.removeItem("rolesautocomplete");
            sessionStorage.removeItem("rolenames");
            return backendAPI.delete(RESOURCE, id);
        };

        this.emptyModel = () => {
            var role = {};
            role["cluster"] = [""];
            role["indices"] = {};
            role["tenants"] = {};
            return role;
        };

        this.addEmptyIndex = (role, indexname, doctypename) => {
            if (!role.indices) {
                role["indices"] = {};
            }
            if (!role.indices[indexname]) {
                role.indices[indexname] = {};
                role.dlsfls[indexname] = {
                    _dls_: "",
                    _fls_: [],
                    _masked_fields_: [],
                    _flsmode_: "whitelist"
                };
            }
            role.indices[indexname][doctypename] = {
                "actiongroups": [""],
                "permissions": []
            };
        }

        this.preSave = (role) => {
            delete role["indexnames"];
            // merge cluster permissions
            var clusterpermissions = backendAPI.mergeCleanArray(role.cluster.actiongroups, role.cluster.permissions);
            // delete tmp permissions
            delete role.cluster["actiongroups"];
            delete role.cluster["permissions"];
            role.cluster = clusterpermissions;

            // same for each index and each doctype
            for (var indexname in role.indices) {
                var index = role.indices[indexname];

                for (var doctypename in index) {
                    var doctype = index[doctypename];
                    var doctypepermissions = backendAPI.mergeCleanArray(doctype.actiongroups, doctype.permissions);
                    delete doctype["actiongroups"];
                    delete doctype["permissions"];
                    index[doctypename] = doctypepermissions;
                }

                // set field prefixes according to FLS mode
                this.setFlsModeToFields(role.dlsfls[indexname]);

                // move back dls and fls
                var dlsfls = role.dlsfls[indexname];
                if(dlsfls) {
                    if (dlsfls["_dls_"].length > 0) {
                        // remove any formatting
                        var dls = dlsfls["_dls_"];
                        try {
                            var dlsJsonObject = JSON.parse(dls);
                            dls = JSON.stringify(dlsJsonObject);
                        } catch (exception) {
                            // no valid json, keep as is.
                        }
                        index["_dls_"] = dls.replace(/(\r\n|\n|\r|\t)/gm,"");;
                    }
                    if (dlsfls["_fls_"].length > 0) {
                        index["_fls_"] = dlsfls["_fls_"];
                    }
                    if (dlsfls["_masked_fields_"].length > 0) {
                        index["_masked_fields_"] = dlsfls["_masked_fields_"];
                    }

                }
            }

            delete role["dlsfls"];

            // tenants
            role["tenants"] = {};
            for (var i = 0, l = role.tenantsArray.length; i < l; i++) {
                var tenant = role.tenantsArray[i];
                if (tenant && tenant.name != "") {
                    role.tenants[tenant.name] = tenant.permissions;
                }
            }

            delete role["tenantsArray"];
            return role;
        };

        this.postFetch = (role) => {

            role = backendAPI.cleanArraysFromDuplicates(role);

            // separate action groups and single permissions on cluster level
            var clusterpermissions = backendAPI.sortPermissions(role.cluster);
            role["cluster"] = {};
            role.cluster["actiongroups"] = clusterpermissions.actiongroups;
            role.cluster["permissions"] = clusterpermissions.permissions;

            // move dls and fls to separate section on top level
            // otherwise its on the same level as the document types
            // and it is hard to separate them in the views. We
            // should think about restructuring the config here, but
            // for the moment we're fiddling with the model directly
            role.dlsfls = {};

            // Handle the case where the readonly flag is set to false.
            // Since "false" is retrieved as a string, the views will
            // not check for boolean true.
            // Also, saving the resource would fail validation if readonly is present when saving.
            if (role.readonly && role.readonly === "false") {
                delete role.readonly;
            }

            if (role.indices) {

                // flat list of indexnames, can't be done in view
                role["indexnames"] = Object.keys(role.indices).sort();

                for (var indexname in role.indices) {

                    var index = role.indices[indexname];

                    var dlsfls = {
                        _dls_: "",
                        _fls_: [],
                        _masked_fields_: [],
                        _flsmode_: "whitelist"
                    };

                    if (index["_dls_"]) {
                        dlsfls._dls_ = index["_dls_"];
                    }
                    if (index["_fls_"]) {
                        dlsfls._fls_ = index["_fls_"];
                    }
                    if (index["_masked_fields_"]) {
                        dlsfls._masked_fields_ = index["_masked_fields_"];
                    }

                    delete role.indices[indexname]["_fls_"];
                    delete role.indices[indexname]["_dls_"];
                    delete role.indices[indexname]["_masked_fields_"];
                    role.dlsfls[indexname] = dlsfls;

                    // determine the fls mode and strip any prefixes
                    this.determineFlsMode(role.dlsfls[indexname]);

                    // sort permissions into actiongroups and single permissions
                    for (var doctypename in index) {
                        var doctype = index[doctypename];
                        var doctypepermissions = backendAPI.sortPermissions(doctype);
                        doctype = {
                            actiongroups: doctypepermissions.actiongroups,
                            permissions: doctypepermissions.permissions
                        }
                        index[doctypename] = doctype;
                    }
                }
            } else {
                role.indices = {};
            }

            // transform tenants to object
            role["tenantsArray"] = [];
            if (role.tenants) {
                var tenantNames = Object.keys(role.tenants).sort();
                tenantNames.forEach(function(tenantName){

                    role.tenantsArray.push(
                        {
                            name: tenantName,
                            permissions: role.tenants[tenantName]
                        }
                    );
                });
            }
            delete role["tenants"];
            return role;
        };

        /**
         * Determine the FLS mode (exclude/include) and
         * strip the prefixes from the fields for
         * display purposes. Rule here is that if one field
         * is excluded, i.e. prefixed with a tilde, we
         * assume exclude (blacklist) mode.
         * @param dlsfls
         */
        this.determineFlsMode = function (dlsfls) {
            // default is whitelisting
            dlsfls["_flsmode_"] = "whitelist";
            // any fields to set?
            var flsFields = dlsfls["_fls_"];
            if (isEmpty(flsFields) || !Array.isArray(flsFields)) {
                return;
            }
            for (var index = 0; index < flsFields.length; ++index) {
                var field = flsFields[index];
                if (field.startsWith("~")) {
                    // clean multiple tildes at the beginning, just in case
                    flsFields[index] = field.replace(/^\~+/, '');
                    dlsfls["_flsmode_"] = "blacklist";
                }
            }
        }

        /**
         * Ensure that all fields are either prefixed with
         * a tilde, or no field is prefixed with a tilde, based
         * on the exclude/include mode of FLS.
         * @param dlsfls
         */
        this.setFlsModeToFields = function(dlsfls) {
            if (!dlsfls) {
                return;
            }
            // any fields to set?
            var flsFields = dlsfls["_fls_"];
            if (isEmpty(flsFields) || !Array.isArray(flsFields)) {
                return;
            }

            for (var index = 0; index < flsFields.length; ++index) {
                var field = flsFields[index];
                // remove any tilde from beginning of string, in case
                // the user has added it in addition to setting mode to blacklist
                // We need just a single tilde here.
                field = field.replace(/^\~+/, '');
                if (!field.startsWith("~") && dlsfls["_flsmode_"] == "blacklist") {
                    flsFields[index] = "~" + field;
                }
            }
        }

        /**
         * Checks whether a role definition is empty. Empty
         * roles are not supported and cannot be saved. We need
         * at least some index or clusterpermissions
         * @param role
         */
        this.isRoleEmpty = function (role) {
            // clean duplicates and remove empty arrays
            role.cluster.actiongroups = backendAPI.cleanArray(role.cluster.actiongroups);
            role.cluster.permissions = backendAPI.cleanArray(role.cluster.permissions);
            var clusterPermsEmpty = role.cluster.actiongroups.length == 0 && role.cluster.permissions.length == 0;
            var indicesEmpty = this.checkIndicesStatus(role).allEmpty;
            return clusterPermsEmpty && indicesEmpty;
        }

        this.checkIndicesStatus = function (role) {

            // index, we need at least one index with one document type with one permissions
            var indicesStatus = {
                allEmpty: true,
                faultyIndices: []
            };
            if (role.indices) {

                var indexNames = Object.keys(role.indices);
                indexNames.forEach(function(indexName) {
                    var docTypeNames = Object.keys(role.indices[indexName]);
                    docTypeNames.forEach(function(docTypeName) {
                        var doctype = role.indices[indexName][docTypeName];
                        // doctype with at least one permission
                        doctype.actiongroups = backendAPI.cleanArray(doctype.actiongroups);
                        doctype.permissions = backendAPI.cleanArray(doctype.permissions);
                        if ((doctype.actiongroups && doctype.actiongroups.length > 0) || (doctype.permissions && doctype.permissions.length > 0)) {
                            indicesStatus.allEmpty = false;
                        } else {
                            // empty doctype
                            indicesStatus.faultyIndices.push(indexName + " / " + docTypeName);
                        }
                    });
                });
            }
            return indicesStatus;
        }

    });
