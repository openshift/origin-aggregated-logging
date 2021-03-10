import { uiModules } from 'ui/modules';

const app = uiModules.get('apps/opendistro_security/configuration', []);

app.directive('securitycErrorMessage', function () {
    return {
        template: require('./errormessage.html'),
        replace: true,
        restrict: 'E'
    };
});
