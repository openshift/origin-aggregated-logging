import { uiModules } from 'ui/modules';
//import { merge } from 'lodash';

const app = uiModules.get('apps/opendistro_security/configuration', []);

app.directive('securitycConfirmationModal', function () {
    return {
        template: require('./confirmationmodal.html'),
        restrict: 'E',
        scope: {},
        controllerAs: 'vm',
        bindToController: {
            /**
             * Dialog title
             * @param {string}
             */
            header: '@',
            /**
             * Dialog body text
             * @param {string}
             */
            body: '@',
            /**
             * Optional params object that would be passed
             * to the on-confirm function
             * @param {object}
             */
            params: '=',
            /**
             * Confirm handler
             * @param {function}
             */
            onConfirm: '&',
            /**
             * Close handler
             * @param {function}
             */
            onClose: '&',
            /**
             * Optional object that extends the default config
             * @todo See if the angular version supports one way binding
             */
            extendConfig: '=',
        },
        controller: function($scope, $timeout) {
            // Default config
            // @todo Annoying to override?
            this.config = {
                buttons: {
                    confirm: {
                        label: 'Confirm',
                        classes: 'kuiButton--primary'
                    },
                    cancel: {
                        label: 'Cancel',
                        classes: 'kuiButton--hollow'
                    }
                }
            };

            this.$onInit = function () {

                if (this.extendConfig) {
                    this.config = angular.merge({}, this.config, this.extendConfig);
                }

                // We want to be able to close the modal with the escape key
                document.addEventListener('keydown', handleCloseOnEsc);
            };

            /**
             * User confirmed the action
             */
            this.confirm = function () {
                if (this.onConfirm()) {
                    this.onConfirm()({
                        params: this.params
                    });
                }

            };

            /**
             * Cancel the confirmation.
             * If available, a "reason" is passed to the handler.
             * Reasons:
             * - cancel (user clicked the cancel button)
             * - overlay (user clicked the overlay)
             * - esc (user hit the escape key)
             * @param {String} reason
             */
            this.closeModal = function (reason) {
                if (this.onClose()) {
                    this.onClose()(reason);
                }
            };

            /**
             * Handle keydown events and close the modal with the escape key
             * @param {Event} event
             */
            let handleCloseOnEsc = (event) => {
                if (event.keyCode === 27) {
                    // Make sure angular is notified
                    $timeout(() => {
                        this.closeModal('esc');
                    });
                }
            };

            /**
             * Handle clicks on the overlay and check whether to close the modal
             * @param {Event} event
             */
            this.closeOnOverlay = function (event) {
                // Make sure we only close on clicks that happened
                // on the overlay itself, and not on its content
                if (!angular.element(event.target).hasClass('js-confirmOverlay')) {
                    return;
                }

                this.closeModal('overlay');
            };

            /**
             * Clean up
             */
            this.$onDestroy = function () {
                document.removeEventListener('keydown', handleCloseOnEsc);
            };
        }
    };
});
