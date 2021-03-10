import { uiModules } from 'ui/modules';

const app = uiModules.get('apps/opendistro_security/configuration', []);

app.directive('securitycListHeader', function () {
    return {
        template: require('./list_header.html'),
        replace: true,
        restrict: 'E'
    };
});
