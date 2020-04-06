import { uiModules } from 'ui/modules';

const app = uiModules.get('apps/opendistro_security/configuration', []);

/**
 * Adds focus to a single input field.
 * Since we may use this in conjunction with UI-Select, we support
 * adding the directive both directly to an input field, but also
 * to a container, in which the element can be found.
 */
app.directive('securitycFormFocusField', function ($timeout) {
    return {
        restrict: 'A',
        scope: {
            focusWhen: '=',
        },
        link: function(scope, el) {
            scope.$watch('focusWhen', function(current, previous) {
                if (current === true && ! previous) {
                    $timeout(function() {
                        // We use several UI-Select instances, so in order to support those we
                        // can also attach this directive to a parent container
                        if (el[0].nodeName.toLowerCase() !== 'input') {
                            let focusable = el[0].querySelector("input[type='text']");
                            if (focusable) {
                                focusable.focus();
                            }
                        } else {
                            // Directive seems to be attached to an input element
                            el[0].focus();
                        }

                    });

                }
            });

        }
    };
});