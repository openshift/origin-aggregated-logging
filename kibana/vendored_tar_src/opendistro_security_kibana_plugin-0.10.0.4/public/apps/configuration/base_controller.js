import { uiModules } from 'ui/modules';
import chrome from 'ui/chrome';
import { SavedObjectsClientProvider } from 'ui/saved_objects';
import { toastNotifications } from 'ui/notify';
import { get } from 'lodash';
import './directives/directives';
import client from './backend_api/client';
import { uniq } from 'lodash';
import { orderBy } from 'lodash';

import clusterpermissions  from './permissions/clusterpermissions';
import indexpermissions  from './permissions/indexpermissions';

import 'ui-select';
import 'ui-select/dist/select.css';

require ('./backend_api/actiongroups');
require ('./systemstate/systemstate');


const app = uiModules.get('apps/opendistro_security/configuration', ['ui.ace', 'ui.select']);

app.controller('securityBaseController', function ($scope, $element, $route, $window, $http, backendAPI, backendActionGroups, backendRoles, kbnUrl, systemstate) {

    var APP_ROOT = `${chrome.getBasePath()}`;
    var API_ROOT = `${APP_ROOT}/api/v1`;

    // props of the child controller
    $scope.service = null;
    $scope.endpoint = null;

    // loading state and loaded resources
    $scope.numresources = "0";
    $scope.loaded = false;

    $scope.title = "Security Base Controller";
    $scope.errorMessage = "";
    $scope.query = "";
    $scope.resource = {};
    $scope.showEditor = false;
    $scope.toggleEditorLabel = "Show JSON";
    $scope.resourceAsJson = null;
    $scope.accessState = "pending";

    $scope.actiongroupNames = [];
    $scope.roleNames = [];

    // objects for autocomplete
    $scope.actiongroupsAutoComplete = {};
    $scope.rolesAutoComplete = {};
    $scope.clusterpermissionsAutoComplete = clusterpermissions;
    $scope.indexpermissionsAutoComplete = indexpermissions;
    $scope.allpermissionsAutoComplete = indexpermissions.concat(clusterpermissions);
    $scope.currentuser = "";

    // modal delete dialogue
    $scope.displayModal = false;
    $scope.deleteModalResourceName = "";

    // edit views modal delete dialogue
    $scope.deleteFromEditModal = {
        displayModal: false,
        params: {},
        header: 'Confirm Delete',
        body: '',
        onConfirm: null,
        onClose: null
    };

    // img assets routes
    $scope.roleMappingsSvgURL = APP_ROOT + "/plugins/opendistro_security/assets/role_mappings.svg";
    $scope.rolesSvgURL = APP_ROOT + "/plugins/opendistro_security/assets/roles.svg";
    $scope.actionGroupsSvgURL = APP_ROOT + "/plugins/opendistro_security/assets/action_groups.svg";
    $scope.internalUserDatabaseSvgURL = APP_ROOT + "/plugins/opendistro_security/assets/internal_user_database.svg";
    $scope.authenticationSvgURL = APP_ROOT + "/plugins/opendistro_security/assets/authentication.svg";
    $scope.purgeCacheSvgURL = APP_ROOT + "/plugins/opendistro_security/assets/purge_cache.svg";

    $scope.title = "Security Configuration";

    $scope.initialiseStates = () => {
        $scope.complianceFeaturesEnabled = systemstate.complianceFeaturesEnabled();
        systemstate.loadRestInfo().then(function(){
            $scope.accessState = "ok";
            $scope.loadActionGroups();
            $scope.loadRoles();
            $scope.currentuser = systemstate.getRestApiInfo().user_name;
        });
    }

    $scope.loadActionGroups = () => {
        var cachedActionGroups = sessionStorage.getItem("actiongroupsautocomplete");
        var cachedActionGroupNames = sessionStorage.getItem("actiongroupnames");

        if (cachedActionGroups) {
            $scope.actiongroupsAutoComplete = JSON.parse(cachedActionGroups);
        }

        if (cachedActionGroupNames) {
            $scope.actiongroupNames = JSON.parse(cachedActionGroupNames);
        }

        if (cachedActionGroupNames && cachedActionGroups) {
            return;
        }

        if(systemstate.endpointAndMethodEnabled("ACTIONGROUPS","GET")) {
            backendActionGroups.listSilent().then((response) => {
                $scope.actiongroupNames = Object.keys(response.data);
                sessionStorage.setItem("actiongroupnames", JSON.stringify($scope.actiongroupNames));
                $scope.actiongroupsAutoComplete = backendActionGroups.listAutocomplete($scope.actiongroupNames);
                sessionStorage.setItem("actiongroupsautocomplete", JSON.stringify($scope.actiongroupsAutoComplete));
            }, (error) => {
                toastNotifications.addDanger({
                    title: 'Unable to load action groups',
                    text: error.data.message,
                });
                $scope.accessState = "forbidden";
            });
        }
    }

    $scope.loadRoles = () => {
        var cachedRoles = sessionStorage.getItem("rolesautocomplete");
        var cachedRoleNames = sessionStorage.getItem("rolenames");

        if (cachedRoles) {
            $scope.rolesAutoComplete = JSON.parse(cachedRoles);
        }

        if (cachedRoleNames) {
            $scope.roleNames = JSON.parse(cachedRoleNames);
        }

        if (cachedRoles && cachedRoleNames) {
            return;
        }

        if(systemstate.endpointAndMethodEnabled("ROLES","GET")) {
            backendRoles.listSilent().then((response) => {
                $scope.rolesAutoComplete = backendRoles.listAutocomplete(Object.keys(response.data));
                $scope.roleNames = Object.keys(response.data);
                sessionStorage.setItem("rolesautocomplete", JSON.stringify($scope.rolesAutoComplete));
                sessionStorage.setItem("rolenames", JSON.stringify(Object.keys(response.data)));
            }, (error) => {
                toastNotifications.addDanger({
                    text: error.data.message,
                });
                $scope.accessState = "forbidden";
            });
        }
    }

    $scope.clearCache = function() {
        backendAPI.clearCache();
    }

    $scope.getDocTypeAutocomplete = () => {
        $scope.indexAutoComplete = backendAPI.indexAutocomplete();
    }

    $scope.endpointAndMethodEnabled = (endpoint, method) => {
        return systemstate.endpointAndMethodEnabled(endpoint, method);
    }

    // +++ START common functions for all controllers +++

    // --- Start navigation
    $scope.edit = function(resourcename) {
        kbnUrl.change('/' +$scope.endpoint.toLowerCase() + '/edit/' + resourcename );
    }

    $scope.new = function(query) {
        kbnUrl.change('/' +$scope.endpoint.toLowerCase() + '/new?name='+query);
    }

    $scope.clone = function(resourcename) {
        kbnUrl.change('/' +$scope.endpoint.toLowerCase() + '/clone/' + resourcename);
    }

    $scope.cancel = function () {
        kbnUrl.change('/' +$scope.endpoint.toLowerCase() );
    }
    // --- End navigation

    $scope.delete = function() {
        $scope.displayModal = false;
        var name = $scope.deleteModalResourceName;
        $scope.deleteModalResourceName = "";
        $scope.service.delete(name)
            .then(() => $scope.cancel());
    }

    $scope.confirmDelete = function(resourcename) {
        $scope.deleteModalResourceName = resourcename;
        $scope.displayModal = true;
    }

    $scope.closeDeleteModal = () => {
        $scope.deleteModalResourceName = "";
        $scope.displayModal = false;
    };


    $scope.aceLoaded = (editor) => {
        editor.session.setOptions({
            tabSize: 2,
            useSoftTabs: false
        });
        editor.$blockScrolling = Infinity;
        editor.setShowPrintMargin(false);
    };

    $scope.aceRwLoaded = (editor) => {
        editor.session.setOptions({
            tabSize: 2,
            useSoftTabs: false
        });
        editor.$blockScrolling = Infinity;
        editor.setShowPrintMargin(false);
    };

    $scope.toggleEditor = (resource) => {
        if ($scope.resourceAsJson == null) {
            $scope.loadJSON(resource)
        }
        $scope.showEditor = !$scope.showEditor;
        $scope.toggleEditorLabel = $scope.showEditor? "Hide JSON" : "Show JSON";
    };

    $scope.loadJSON = function(resource) {
        // copy resource, we don't want to modify current edit session
        var resourceCopy = JSON.parse(JSON.stringify(resource));
        $scope.resourceAsJson = JSON.stringify($scope.service.preSave(resourceCopy), null, 2);
    }

    $scope.checkActionGroupExists = function (array, index, item) {
        if($scope.actiongroupNames.indexOf(item) == -1) {
            array[index] = "";
        }
    }

    $scope.addArrayEntry = function (resource, fieldname, value) {
        if(!resource[fieldname] || !Array.isArray(resource[fieldname])) {
            resource[fieldname] = [];
        }
        resource[fieldname].push(value);

    };

    /**
     * Remove an array entry after user confirmation, or when the user removes an empty entry
     * @param {array} array
     * @param {object} item
     */
    let removeArrayEntry = function (array, item) {
        var index = array.indexOf(item);
        if (index > -1) {
            array.splice(index, 1);
        }
    };


    /**
     * Ask for confirmation before deleting an entry
     * @param {array} array
     * @param {string} item
     */
    $scope.confirmRemoveArrayEntry = function (array, item) {
        if(!Array.isArray(array) || array.indexOf(item) === -1) {
            return;
        }

        if (item && item.length > 0) {
            $scope.deleteFromEditModal = {
                displayModal: true,
                header: 'Confirm Delete',
                body: `Are you sure you want to delete '${item}'?`,
                onConfirm: function() {
                    removeArrayEntry(array, item);
                    $scope.closeDeleteFromEditModal()
                },
                onClose: $scope.closeDeleteFromEditModal
            };
        } else {
            removeArrayEntry(array, item);
        }
    };

    /**
     * Close the confirmation dialog
     * @param {string} reason
     */
    $scope.closeDeleteFromEditModal = function () {
        $scope.deleteFromEditModal = {
            displayModal: false,
            params: null
        };
    };

    /**
     * @todo Remove when we use the new confirmation dialog everywhere
     * @deprecated
     * @param array
     * @param item
     */

    $scope.removeArrayEntry = function (array, item) {
        if(!Array.isArray(array)) {
            return;
        }
        if (item && item.length > 0) {
            if (!confirm(`Are you sure you want to delete '${item}'?`)) {
                return;
            }
        }
        var index = array.indexOf(item);
        array.splice(index, 1);
    }

    $scope.lastArrayEntryEmpty = function (array) {

        if (!array || typeof array == 'undefined' || array.length == 0) {
            return false;
        }

        var entry = array[array.length - 1];

        if (typeof entry === 'undefined' || entry.length == 0) {
            return true;
        }

        return false;
    }

    $scope.removeObjectKey = function (theobject, key) {
        if (theobject[key]) {
            if (confirm(`Are you sure you want to delete '${key}'?`)) {
                delete theobject[key];
            }
        }
    }

    $scope.addObjectKey = function (theobject, key, value) {
        theobject[key] = value;
    }

    $scope.sortObjectArray = function (objectArray, sortProperty) {
        //return orderBy(objectArray, [sortProperty], ["asc"]);
        return objectArray;
    }

    /**
     * Ask for confirmation before deleting an entry
     * @param {array} thearray
     * @param {int} index
     * @param {string} value
     */
    $scope.confirmRemoveFromObjectArray = function(thearray, index, value) {
        // We're not checking the value here, so we may need to adjust the body
        let body = (value === '') ? 'Are you sure you want to delete this?' : `Are you sure you want to delete '${value}'?`;
        $scope.deleteFromEditModal = {
            displayModal: true,
            header: 'Confirm Delete',
            body: body,
            onConfirm: function() {
                thearray.splice(index, 1);
                $scope.closeDeleteFromEditModal()
            },
            onClose: $scope.closeDeleteFromEditModal
        }
    };

    /**
     * Remove when we've tested all dialogs
     * @deprecated
     * @param thearray
     * @param index
     * @param value
     */
    $scope.removeFromObjectArray = function (thearray, index, value) {
        if (confirm(`Are you sure you want to delete '${value}'?`)) {
            thearray.splice(index, 1);
        }
    }

    $scope.addToObjectArray = function (thearray, value) {
        return thearray.push(value);
    }

    // helper function to use Object.keys in templates
    $scope.keys = function (object) {
        if (object) {
            return Object.keys(object).sort();
        }
    }

    $scope.flatten = function (list, textAttribute) {
        return uniq(list.reduce((result, item) => {
            const text = item[textAttribute];
            if (text) {
                result.push(text);
            }
            return result;
        }, [])).sort();
    }


    // --- init ---
    $scope.initialiseStates();

});

app.filter('escape', function() {
    return window.encodeURIComponent;
});

app.filter('unsafe', function($sce) {
    return $sce.trustAsHtml;
});
