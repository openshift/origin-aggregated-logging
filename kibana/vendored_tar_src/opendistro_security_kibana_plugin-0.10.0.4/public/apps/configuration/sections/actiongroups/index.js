import angular from 'angular';
import uiRoutes from 'ui/routes';
import sectionTemplate from './views/index.html';
import editTemplate from './views/edit.html';
import './controller';
import '../../base_controller';
import '../../directives/directives';

import 'ui/autoload/styles';
import 'plugins/opendistro_security/apps/configuration/configuration.less';

uiRoutes
    .when('/actiongroups', {
      template: sectionTemplate
    })
    .when('/actiongroups/edit/:resourcename', {
      template: editTemplate
    })
    .when('/actiongroups/clone/:resourcename', {
        template: editTemplate
    })
    .when('/actiongroups/new', {
      template: editTemplate
    });
