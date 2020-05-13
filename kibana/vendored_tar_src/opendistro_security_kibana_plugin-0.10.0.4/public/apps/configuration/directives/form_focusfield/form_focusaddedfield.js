import { uiModules } from 'ui/modules';

const app = uiModules.get('apps/opendistro_security/configuration', []);

/**
 * Attaches a mutation observer and checks for
 * dynamically added input type="text" elements
 */
app.directive('securitycFormFocusAddedField', function ($timeout) {
    return {
        restrict: 'A',
        link: function(scope, el) {

            /**
             * The MutationObserver
             * @type {null|MutationObserver}
             */
            let observer = null;

            /**
             * Options for the MutationObserver
             * @type {{childList: boolean, subtree: boolean}}
             */
            let config = {
                childList: true,
                subtree: true,
            };

            // Callback function to execute when mutations are observed
            let observerCallback = function(mutationsList) {

                // We only want mutations with added nodes
                let mutationsWithAdditions = mutationsList.filter((mutation) => {
                    return (mutation.addedNodes.length);
                });

                if (mutationsWithAdditions.length === 0) {
                    return;
                }

                // For now, only bother with the first mutation
                let mutation = mutationsWithAdditions[0];

                // Check the first added node and make sure it's an ELEMENT_NODE (nodeType === 1)
                if (mutation.addedNodes[0].nodeType === 1) {

                    let focusable = mutation.addedNodes[0].querySelector("input[type='text']");
                    // Only focus on elements without a value for now
                    if (focusable && focusable.value === '') {
                        focusable.focus();
                    }
                }
            };

            if ('MutationObserver' in window) {
                // Use a $timeout to avoid listening for mutations on the first render
                $timeout(function() {
                    observer = new MutationObserver(observerCallback);
                    observer.observe(el[0], config);
                });

            }

            /**
             * Clean up
             */
            el.on('$destroy', function() {
                if (observer !== null) {
                    observer.disconnect();
                }
            });
        }
    };
});