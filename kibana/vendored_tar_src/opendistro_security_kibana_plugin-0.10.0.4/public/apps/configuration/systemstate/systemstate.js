import chrome from 'ui/chrome';
import { uiModules } from 'ui/modules';
import { get } from 'lodash';
import { isEmpty } from 'lodash';

/**
 * Role mappings API client service.
 */
uiModules.get('apps/opendistro_security/configuration', [])
    .service('systemstate', function ($http) {

        const ROOT = chrome.getBasePath();
        const API_ROOT = `${ROOT}/api/v1`;

        this.complianceFeaturesEnabled = () => {
            return true;
            // const features = get(this.getSystemInfo(), 'license.features', []);
            // if (Array.isArray(features)) {
            //     return features.indexOf("COMPLIANCE") != -1;
            // }
            // return false;
        }

        this.endpointAndMethodEnabled = (endpoint, method) => {
            var restInfo = this.getRestApiInfo();
            if (restInfo && restInfo.disabled_endpoints) {
                if (restInfo.disabled_endpoints[endpoint]) {
                    return restInfo.disabled_endpoints[endpoint].indexOf(method) == -1;
                } else {
                    return true;
                }
            }
            return false;
        }

        this.getRestApiInfo = () => {
            return this.getAndParse('restapiinfo');
        }

        this.getAndParse = (key) => {
            var objectString = sessionStorage.getItem(key);
            try {
                return JSON.parse(objectString);
            } catch (e) {
                return {};
            }
        }

        this.loadRestInfo =  async function()  {
            // load restinfo if not found in cache
            if (!sessionStorage.getItem('restapiinfo')) {
                return $http.get(`${API_ROOT}/restapiinfo`).then(function(response) {
                    sessionStorage.setItem('restapiinfo', JSON.stringify(response.data));
                }).catch(function(error) {
                    sessionStorage.setItem('restapiinfo', '{}');
                });
            }
        }

    });
