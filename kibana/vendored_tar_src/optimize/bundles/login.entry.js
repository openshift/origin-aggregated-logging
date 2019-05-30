
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
    "apm",
    "apm_oss",
    "beats_management",
    "canvas",
    "cloud",
    "console",
    "console_extensions",
    "cross_cluster_replication",
    "dashboard_mode",
    "elasticsearch",
    "graph",
    "grokdebugger",
    "index_lifecycle_management",
    "index_management",
    "infra",
    "input_control_vis",
    "inspector_views",
    "interpreter",
    "kbn_doc_views",
    "kbn_vislib_vis_types",
    "kibana",
    "kuery_autocomplete",
    "license_management",
    "logstash",
    "maps",
    "markdown_vis",
    "metric_vis",
    "metrics",
    "ml",
    "monitoring",
    "notifications",
    "oss_telemetry",
    "region_map",
    "remote_clusters",
    "reporting",
    "rollup",
    "searchprofiler",
    "security",
    "spaces",
    "state_session_storage_redirect",
    "status_page",
    "table_vis",
    "tagcloud",
    "task_manager",
    "tile_map",
    "tilemap",
    "timelion",
    "translations",
    "upgrade_assistant",
    "uptime",
    "vega",
    "watcher",
    "xpack_main"
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
        require('plugins/security/views/login');
      }
    });
    
    const coreStartContract = coreSystem.start();
    
    if (i18nError) {
      coreStartContract.fatalErrors.add(i18nError);
    }
  });
