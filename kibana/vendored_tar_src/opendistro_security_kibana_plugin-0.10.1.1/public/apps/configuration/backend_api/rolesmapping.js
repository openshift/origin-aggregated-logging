import { uiModules } from 'ui/modules';
import { merge } from 'lodash';
import { uniq } from 'lodash';
import client from './client';

/**
 * Role mappings API client service.
 */
uiModules.get('apps/opendistro_security/configuration', [])
    .service('backendrolesmapping', function (backendAPI, Promise, $http) {

        const RESOURCE = 'rolesmapping';

        this.title = {
            singular: 'role mapping',
            plural: 'role mappings'
        };

        this.newLabel = "Role";

        this.list = () => {
            return backendAPI.list(RESOURCE);
        };

        this.get = (id) => {
            return backendAPI.get(RESOURCE, id);
        };

        this.getSilent = (id) => {
            return backendAPI.getSilent(RESOURCE, id);
        };

        this.save = (actiongroupname, data) => {
            var data = this.preSave(data);
            return backendAPI.save(RESOURCE, actiongroupname, data);
        };

        this.delete = (id) => {
            return backendAPI.delete(RESOURCE, id);
        };

        this.emptyModel = () => {
            var rolemapping = {};
            rolemapping.users = [];
            rolemapping.hosts = [];
            rolemapping.backendroles = [];
            return rolemapping;
        };

        this.preSave = (rolemapping) => {
            rolemapping.users = this.cleanArray(rolemapping.users);
            rolemapping.backendroles = this.cleanArray(rolemapping.backendroles);
            rolemapping.hosts = this.cleanArray(rolemapping.hosts);
            return rolemapping;
        };

        this.postFetch = (rolemapping) => {
            // Handle the case where the readonly flag is set to false.
            // Since "false" is retrieved as a string, the views will
            // not check for boolean true.
            // Also, saving the resource would fail validation if readonly is present when saving.
            if (rolemapping.readonly && rolemapping.readonly === "false") {
                delete rolemapping.readonly;
            }

            rolemapping = backendAPI.cleanArraysFromDuplicates(rolemapping);
            return rolemapping;
        };

        this.cleanArray = (thearray) => {
            if (thearray && Array.isArray(thearray)) {
                // remove empty entries
                thearray = thearray.filter(e => String(e).trim());
                // remove duplicate entries
                thearray = uniq(thearray);
                return thearray;
            }
        };

    });
