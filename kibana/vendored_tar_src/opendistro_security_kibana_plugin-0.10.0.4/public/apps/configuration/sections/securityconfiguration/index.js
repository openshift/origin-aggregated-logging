import angular from 'angular';
import uiRoutes from 'ui/routes';
import sectionTemplate from './views/index.html';

import '../../base_controller';
import './controller';
import '../../directives/directives';

import 'ui/autoload/styles';
import 'plugins/opendistro_security/apps/configuration/configuration.less';

uiRoutes
    .when('/securityconfiguration', {
        template: sectionTemplate
    });
