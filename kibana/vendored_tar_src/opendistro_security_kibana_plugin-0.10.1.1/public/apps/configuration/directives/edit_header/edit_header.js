import { uiModules } from 'ui/modules';

const app = uiModules.get('apps/opendistro_security/configuration', []);

app.directive('securitycEditHeader', function () {
    return {
        template: require('./edit_header.html'),
        replace: true,
        restrict: 'E'
    };
});
