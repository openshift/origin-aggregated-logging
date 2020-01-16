
/**
 * Kibana entry file
 *
 * This is programmatically created and updated, do not modify
 *
 * context: {
  "env": "production",
  "kbnVersion": "6.8.1",
  "buildNum": 20385,
  "plugins": [
    "apm_oss",
    "console",
    "elasticsearch",
    "input_control_vis",
    "inspector_views",
    "interpreter",
    "kbn_doc_views",
    "kbn_vislib_vis_types",
    "kibana",
    "markdown_vis",
    "metric_vis",
    "metrics",
    "region_map",
    "state_session_storage_redirect",
    "status_page",
    "table_vis",
    "tagcloud",
    "tile_map",
    "timelion",
    "vega"
  ]
}
 */

// import global polyfills before everything else
import 'babel-polyfill';
import 'custom-event-polyfill';
import 'whatwg-fetch';
import 'abortcontroller-polyfill';
import 'childnode-remove-polyfill';

import { i18n } from '@kbn/i18n';
import { CoreSystem } from '__kibanaCore__'

const injectedMetadata = JSON.parse(document.querySelector('kbn-injected-metadata').getAttribute('data'));

i18n.load(injectedMetadata.i18n.translationsUrl)
  .catch(e => e)
  .then((i18nError) => {
    const coreSystem = new CoreSystem({
      injectedMetadata,
      rootDomElement: document.body,
      requireLegacyFiles: () => {
        require('plugins/state_session_storage_redirect');
      }
    });
    
    const coreStartContract = coreSystem.start();
    
    if (i18nError) {
      coreStartContract.fatalErrors.add(i18nError);
    }
  });
