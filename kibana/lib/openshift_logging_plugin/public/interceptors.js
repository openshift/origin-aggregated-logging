import chrome from 'ui/chrome';
import { uiModules } from 'ui/modules';
const app = uiModules.get('apps/openshift_logging_plugin/index');

function redirectOnSessionTimeout($window) {
    const APP_ROOT = `${chrome.getBasePath()}`;
    const path = chrome.removeBasePath($window.location.pathname);
    $window.location.href = APP_ROOT.substring(0,path.length + 1) + '/oauth/sign_out'
}

app.factory('errorInterceptor', function ($q, $window) {

    return {
        responseError: function (response) {
          console.info(response)
          //status -1 when failing some cors redirect
          if (response.status && (response.status == 401 || response.status === -1)) { 
              console.log("Session expired. Redirecting to sign_off to refresh")
              redirectOnSessionTimeout($window);
          }

          // If unhandled, we just pass the error on to the next handler.
          return $q.reject(response);
        }
    };
});

/**
 * Make sure that we add the interceptor to the existing ones.
 */
app.config(function($httpProvider) {
    $httpProvider.interceptors.push('errorInterceptor');
});

/**
 * Setup a wrapper around fetch so that we can
 * handle session timeouts on ajax calls made
 * by the kfetch component
 * @param $window
 */
function setupResponseErrorHandler($window) {
    if (!$window.fetch) {
        return;
    }

    const nativeFetch = $window.fetch;
    $window.fetch = (url, config) => {
        return nativeFetch(url, config)
            .then(async(result) => {
                if (result.status && (result.status === 401 || result.status === -1)) {
                    try {
                        redirectOnSessionTimeout($window);
                    } catch (error) {
                        console.log(error)
                    }
                }

                return result;
            });
    };
}

export function enableConfiguration($http, $window) {
    setupResponseErrorHandler($window);
}

app.run(enableConfiguration);
