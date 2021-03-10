import { uiModules } from 'ui/modules';
import { merge } from 'lodash';
import { uniq, cloneDeep } from 'lodash';
import client from './client';

/**
 * Internal users API client service.
 */
uiModules.get('apps/opendistro_security/configuration', [])
    .service('backendInternalUsers', function (backendAPI, Promise, $http) {

        const RESOURCE = 'internalusers';

        this.title = {
            singular: 'internal user',
            plural: 'internal users'
        };

        this.newLabel = "Username";

        this.list = () => {
            return backendAPI.list(RESOURCE);
        };

        this.get = (username) => {
            return backendAPI.get(RESOURCE, username);
        };

        this.save = (username, data) => {
            let dataToSave = cloneDeep(data);
            dataToSave = this.preSave(dataToSave);

            return backendAPI.save(RESOURCE, username, dataToSave, false);
        };

        this.delete = (username) => {
            return backendAPI.delete(RESOURCE, username);
        };

        this.emptyModel = () => {
            var user = {};
            user["password"] = "";
            user["passwordConfirmation"] = "";
            user.roles = [];
            user.attributesArray = [];
            return user;
        };

        this.preSave = (user) => {
            delete user["passwordConfirmation"];
            // remove empty roles
            user.roles = user.roles.filter(e => String(e).trim());
            // remove duplicate roles
            user.roles = uniq(user.roles);

            // attribiutes
            user["attributes"] = {};
            for (var i = 0, l = user.attributesArray.length; i < l; i++) {
                var entry = user.attributesArray[i];
                if (entry && entry.key != "") {
                    user.attributes[entry.key] = entry.value;
                }
            }
            delete user["attributesArray"];
            return user;
        };

        this.postFetch = (user) => {
            user = backendAPI.cleanArraysFromDuplicates(user);
            delete user["hash"];
            user["password"] = "";
            user["passwordConfirmation"] = "";
            if (!user.roles) {
                user.roles = [];
            }

            // Handle the case where the readonly flag is set to false.
            // Since "false" is retrieved as a string, the views will
            // not check for boolean true.
            // Also, saving the resource would fail validation if readonly is present when saving.
            if (user.readonly && user.readonly === "false") {
                delete user.readonly;
            }

            // transform user attributes to object
            user["attributesArray"] = [];
            if (user.attributes) {
                var attributeNames = Object.keys(user.attributes).sort();
                attributeNames.forEach(function(attributeName){

                    user.attributesArray.push(
                        {
                            key: attributeName,
                            value: user.attributes[attributeName]
                        }
                    );
                });
            }
            return user;
        };

    });
