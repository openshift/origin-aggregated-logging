import { uiModules } from 'ui/modules';
import client from './client';

/**
 * security configuration client service.
 */
uiModules.get('apps/opendistro_security/configuration', [])
    .service('securityConfiguration', function (backendAPI, Promise, $http) {

        const RESOURCE = 'securityconfig';

        this.title = {
            singular: 'Authentication / Authorization configuration',
            plural: 'Authentication / Authorization configuration'
        };

        this.list = () => {
            return backendAPI.list(RESOURCE);
        };


        this.postFetch = (securityconfig) => {
            return securityconfig;
        };

    });
