import { toastNotifications } from 'ui/notify';
import { uiModules } from 'ui/modules';
import { merge } from 'lodash';
import { uniq } from 'lodash';
import { isPlainObject } from 'lodash';
import { isEmpty } from 'lodash';
import chrome from 'ui/chrome';

/**
 * Backend API client service.
 */
uiModules.get('apps/opendistro_security/configuration', [])
    .service('backendAPI', function (Promise, $http, $window, kbnUrl, securityAccessControl) {

        // Take the basePath configuration value into account
        // @url https://www.elastic.co/guide/en/kibana/current/development-basepath.html
        const AUTH_BACKEND_API_ROOT = chrome.addBasePath("/api/v1");

        this.testConnection =  () => {

            return $http.post(`${AUTH_BACKEND_API_ROOT}/get/config`)
                .then((response) => {
                    return 200;
                })
                .catch((error) => {
                    if (error.status) {
                        return error.status;
                    } else {
                        return 500;
                    }
                });
        };

        this.get = function(resourceName, id) {
            return $http.get(`${AUTH_BACKEND_API_ROOT}/configuration/${resourceName}/${id}`)
                .then((response) => {
                    return response.data;
                })
                .catch((error) => {
                    if (error.status == 403) {
                        securityAccessControl.logout();
                    } else {
                        toastNotifications.addDanger({
                            title: 'Unable to load data.',
                            text: error.data.message,
                        });
                    }
                    throw error;
                });
        };

        this.getSilent = function(resourceName, id, showError) {
            showError = typeof showError !== 'undefined' ? showError : true;
            return $http.get(`${AUTH_BACKEND_API_ROOT}/configuration/${resourceName}/${id}`)
                .then((response) => {
                    return response.data;
                })
                .catch((error) => {
                    // nothing
                });
        };

        this.save = (resourceName, id, data, showToastOnError = true) => {
            let url = `${AUTH_BACKEND_API_ROOT}/configuration/${resourceName}/${id}`;
            return $http.post(url, data)
                .then((response) => {
                    toastNotifications.addSuccess({
                        title: `'${decodeURIComponent(id)}' saved.`
                    });
                })
                .catch((error) => {
                    if (error.status == 403) {
                        securityAccessControl.logout();
                    } else if(showToastOnError) {
                        toastNotifications.addDanger({
                            text: error.data.message
                        });
                    }
                    throw error;
                });
        };

        this.saveWithoutId = (resourceName, data, showToastOnError = true) => {
            let url = `${AUTH_BACKEND_API_ROOT}/configuration/${resourceName}`;
            return $http.post(url, data)
                .then((response) => {
                    toastNotifications.addSuccess({
                        title: `'${resourceName}' saved.`
                    });
                })
                .catch((error) => {
                    if (error.status == 403) {
                        securityAccessControl.logout();
                    } else if(showToastOnError) {
                        toastNotifications.addDanger({
                            text: error.data.message || error.statusText
                        });
                    }
                    throw error;
                });
        };

        this.delete = (resourceName, id) => {
            return $http.delete(`${AUTH_BACKEND_API_ROOT}/configuration/${resourceName}/${id}`)
                .then((response) => {
                    toastNotifications.addSuccess({
                        title: `'${decodeURIComponent(id)}' deleted.`
                    });
                })
                .catch((error) => {
                    if (error.status == 403) {
                        securityAccessControl.logout();
                    } else {
                        toastNotifications.addDanger({
                            title: 'Unable to delete data.',
                            text: error.data.message,
                        });
                    }
                    throw error;
                });
        };

        this.list = (resourceName)  => {
            return $http.get(`${AUTH_BACKEND_API_ROOT}/configuration/${resourceName}`)
                .then((response) => {
                    return response.data;
                })
                .catch((error) => {
                    if (error.status == 403) {
                        securityAccessControl.logout();
                    } else {
                        toastNotifications.addDanger({
                            title: 'Unable to load data.',
                            text: error.data.message
                        });
                    }
                    
                    throw error;
                });
        };

        this.listSilent = (resourceName)  => {
            return $http.get(`${AUTH_BACKEND_API_ROOT}/configuration/${resourceName}`)
                .then((response) => {
                    return response.data;
                })
                .catch((error) => {
                    // nothing
                });
        };

        this.listAutocomplete = (names) => {
            var completeList = [];
            names.sort().forEach( function(name) {
                var autocomplete = {};
                autocomplete["name"] = name;
                completeList.push(autocomplete);
            } );
            return completeList;
        };

        this.clearCache = () => {
            return $http.delete(`${AUTH_BACKEND_API_ROOT}/configuration/cache`)
                .then((response) => {
                    toastNotifications.addSuccess({
                        title: response.data.message
                    });
                })
                .catch((error) => {
                    if (error.status == 403) {
                        securityAccessControl.logout();
                    } else {
                        toastNotifications.addDanger({
                            title: 'Unable to clear cache.',
                            text: error.data.message,
                        });
                    }
                    throw error;
                });
        };

        this.cleanArraysFromDuplicates = function(theobject) {

            // We assume we don't have any mixed arrays,
            // i.e. only arrays of one type
            if (Array.isArray(theobject) && !isEmpty(theobject)) {

                var firstEntry = theobject[0];

                // string arrays, clean it
                if (isString(firstEntry)) {
                    return this.cleanArray(theobject);
                }

                // object array, traverse down
                if (isPlainObject(firstEntry)) {
                    for(var i = 0; i<theobject.length; i++) {
                        theobject[i] = this.cleanArraysFromDuplicates(theobject[i]);
                    }
                }
                // something else ...
                return theobject;
            }

            // Object, traverse keys
            if (isPlainObject(theobject)) {
                var keys = Object.keys(theobject);
                for (var i = 0; i < keys.length; i++) {
                    theobject[keys[i]] = this.cleanArraysFromDuplicates(theobject[keys[i]])
                }
            }
            return theobject;
        }

        this.mergeCleanArray = (array1, array2) => {
            var merged = [];
            if (array1){
                merged = merged.concat(array1);
            }
            if (array2) {
                merged = merged.concat(array2);
            }
            merged = this.cleanArray(merged);
            return merged;
        };


        this.cleanArray = (thearray) => {
            if (!thearray) {
                return [];
            }
            if (!Array.isArray(thearray)) {
                return;
            }
            // remove empty entries
            thearray = thearray.filter(e => String(e).trim());
            // remove duplicate entries
            thearray = uniq(thearray);
            return thearray;
        };

        this.sortPermissions = (permissionsArray) => {
            var actiongroups = [];
            var permissions = [];
            if (permissionsArray && Array.isArray(permissionsArray)) {
                permissionsArray.forEach(function (entry) {
                    if (entry.startsWith("cluster:") || entry.startsWith("indices:")) {
                        permissions.push(entry);
                    } else {
                        actiongroups.push(entry);
                    }
                });
            }
            return {
                actiongroups: actiongroups,
                permissions: permissions
            }
        };

        // taken from lodash, not provided by Kibana
        var isString = function(val) {
            return typeof val === 'string' || ((!!val && typeof val === 'object') && Object.prototype.toString.call(val) === '[object String]');
        }
    });
