'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.createMetricbeatCloudInstructions = exports.createMetricbeatInstructions = undefined;
exports.metricbeatEnableInstructions = metricbeatEnableInstructions;
exports.metricbeatStatusCheck = metricbeatStatusCheck;
exports.onPremInstructions = onPremInstructions;
exports.onPremCloudInstructions = onPremCloudInstructions;
exports.cloudInstructions = cloudInstructions;

var _i18n = require('@kbn/i18n');

var _instruction_variant = require('./instruction_variant');

var _onprem_cloud_instructions = require('./onprem_cloud_instructions');

var _get_space_id_for_beats_tutorial = require('../lib/get_space_id_for_beats_tutorial');

/*
 * Licensed to Elasticsearch B.V. under one or more contributor
 * license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright
 * ownership. Elasticsearch B.V. licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

const createMetricbeatInstructions = exports.createMetricbeatInstructions = context => ({
  INSTALL: {
    OSX: {
      title: _i18n.i18n.translate('kbn.common.tutorials.metricbeatInstructions.install.osxTitle', {
        defaultMessage: 'Download and install Metricbeat'
      }),
      textPre: _i18n.i18n.translate('kbn.common.tutorials.metricbeatInstructions.install.osxTextPre', {
        defaultMessage: 'First time using Metricbeat? See the [Getting Started Guide]({link}).',
        values: { link: '{config.docs.beats.metricbeat}/metricbeat-getting-started.html' }
      }),
      commands: ['curl -L -O https://artifacts.elastic.co/downloads/beats/metricbeat/metricbeat-{config.kibana.version}-darwin-x86_64.tar.gz', 'tar xzvf metricbeat-{config.kibana.version}-darwin-x86_64.tar.gz', 'cd metricbeat-{config.kibana.version}-darwin-x86_64/']
    },
    DEB: {
      title: _i18n.i18n.translate('kbn.common.tutorials.metricbeatInstructions.install.debTitle', {
        defaultMessage: 'Download and install Metricbeat'
      }),
      textPre: _i18n.i18n.translate('kbn.common.tutorials.metricbeatInstructions.install.debTextPre', {
        defaultMessage: 'First time using Metricbeat? See the [Getting Started Guide]({link}).',
        values: { link: '{config.docs.beats.metricbeat}/metricbeat-getting-started.html' }
      }),
      commands: ['curl -L -O https://artifacts.elastic.co/downloads/beats/metricbeat/metricbeat-{config.kibana.version}-amd64.deb', 'sudo dpkg -i metricbeat-{config.kibana.version}-amd64.deb'],
      textPost: _i18n.i18n.translate('kbn.common.tutorials.metricbeatInstructions.install.debTextPost', {
        defaultMessage: 'Looking for the 32-bit packages? See the [Download page]({link}).',
        values: { link: 'https://www.elastic.co/downloads/beats/metricbeat' }
      })
    },
    RPM: {
      title: _i18n.i18n.translate('kbn.common.tutorials.metricbeatInstructions.install.rpmTitle', {
        defaultMessage: 'Download and install Metricbeat'
      }),
      textPre: _i18n.i18n.translate('kbn.common.tutorials.metricbeatInstructions.install.rpmTextPre', {
        defaultMessage: 'First time using Metricbeat? See the [Getting Started Guide]({link}).',
        values: { link: '{config.docs.beats.metricbeat}/metricbeat-getting-started.html' }
      }),
      commands: ['curl -L -O https://artifacts.elastic.co/downloads/beats/metricbeat/metricbeat-{config.kibana.version}-x86_64.rpm', 'sudo rpm -vi metricbeat-{config.kibana.version}-x86_64.rpm'],
      textPost: _i18n.i18n.translate('kbn.common.tutorials.metricbeatInstructions.install.debTextPost', {
        defaultMessage: 'Looking for the 32-bit packages? See the [Download page]({link}).',
        values: { link: 'https://www.elastic.co/downloads/beats/metricbeat' }
      })
    },
    WINDOWS: {
      title: _i18n.i18n.translate('kbn.common.tutorials.metricbeatInstructions.install.windowsTitle', {
        defaultMessage: 'Download and install Metricbeat'
      }),
      textPre: _i18n.i18n.translate('kbn.common.tutorials.metricbeatInstructions.install.windowsTextPre', {
        defaultMessage: 'First time using Metricbeat? See the [Getting Started Guide]({metricbeatLink}).\n\
 1. Download the Metricbeat Windows zip file from the [Download]({elasticLink}) page.\n\
 2. Extract the contents of the zip file into {folderPath}.\n\
 3. Rename the {directoryName} directory to `Metricbeat`.\n\
 4. Open a PowerShell prompt as an Administrator (right-click the PowerShell icon and select \
**Run As Administrator**). If you are running Windows XP, you might need to download and install PowerShell.\n\
 5. From the PowerShell prompt, run the following commands to install Metricbeat as a Windows service.',
        values: {
          directoryName: '`metricbeat-{config.kibana.version}-windows`',
          folderPath: '`C:\\Program Files`',
          metricbeatLink: '{config.docs.beats.metricbeat}/metricbeat-getting-started.html',
          elasticLink: 'https://www.elastic.co/downloads/beats/metricbeat'
        }
      }),
      commands: ['cd "C:\\Program Files\\Metricbeat"', '.\\install-service-metricbeat.ps1'],
      textPost: _i18n.i18n.translate('kbn.common.tutorials.metricbeatInstructions.install.windowsTextPost', {
        defaultMessage: 'Modify the settings under `output.elasticsearch` in the {path} file to point to your Elasticsearch installation.',
        values: { path: '`C:\\Program Files\\Metricbeat\\metricbeat.yml`' }
      })
    }
  },
  START: {
    OSX: {
      title: _i18n.i18n.translate('kbn.common.tutorials.metricbeatInstructions.start.osxTitle', {
        defaultMessage: 'Start Metricbeat'
      }),
      textPre: _i18n.i18n.translate('kbn.common.tutorials.metricbeatInstructions.start.osxTextPre', {
        defaultMessage: 'The `setup` command loads the Kibana dashboards. If the dashboards are already set up, omit this command.'
      }),
      commands: ['./metricbeat setup', './metricbeat -e']
    },
    DEB: {
      title: _i18n.i18n.translate('kbn.common.tutorials.metricbeatInstructions.start.debTitle', {
        defaultMessage: 'Start Metricbeat'
      }),
      textPre: _i18n.i18n.translate('kbn.common.tutorials.metricbeatInstructions.start.debTextPre', {
        defaultMessage: 'The `setup` command loads the Kibana dashboards. If the dashboards are already set up, omit this command.'
      }),
      commands: ['sudo metricbeat setup', 'sudo service metricbeat start']
    },
    RPM: {
      title: _i18n.i18n.translate('kbn.common.tutorials.metricbeatInstructions.start.rpmTitle', {
        defaultMessage: 'Start Metricbeat'
      }),
      textPre: _i18n.i18n.translate('kbn.common.tutorials.metricbeatInstructions.start.rpmTextPre', {
        defaultMessage: 'The `setup` command loads the Kibana dashboards. If the dashboards are already set up, omit this command.'
      }),
      commands: ['sudo metricbeat setup', 'sudo service metricbeat start']
    },
    WINDOWS: {
      title: _i18n.i18n.translate('kbn.common.tutorials.metricbeatInstructions.start.windowsTitle', {
        defaultMessage: 'Start Metricbeat'
      }),
      textPre: _i18n.i18n.translate('kbn.common.tutorials.metricbeatInstructions.start.windowsTextPre', {
        defaultMessage: 'The `setup` command loads the Kibana dashboards. If the dashboards are already set up, omit this command.'
      }),
      commands: ['.\\metricbeat.exe setup', 'Start-Service metricbeat']
    }
  },
  CONFIG: {
    OSX: {
      title: _i18n.i18n.translate('kbn.common.tutorials.metricbeatInstructions.config.osxTitle', {
        defaultMessage: 'Edit the configuration'
      }),
      textPre: _i18n.i18n.translate('kbn.common.tutorials.metricbeatInstructions.config.osxTextPre', {
        defaultMessage: 'Modify {path} to set the connection information:',
        values: {
          path: '`metricbeat.yml`'
        }
      }),
      commands: ['output.elasticsearch:', '  hosts: ["<es_url>"]', '  username: "elastic"', '  password: "<password>"', 'setup.kibana:', '  host: "<kibana_url>"', (0, _get_space_id_for_beats_tutorial.getSpaceIdForBeatsTutorial)(context)],
      textPost: _i18n.i18n.translate('kbn.common.tutorials.metricbeatInstructions.config.osxTextPost', {
        defaultMessage: 'Where {passwordTemplate} is the password of the `elastic` user, {esUrlTemplate} is the URL of Elasticsearch, \
and {kibanaUrlTemplate} is the URL of Kibana.',
        values: {
          passwordTemplate: '`<password>`',
          esUrlTemplate: '`<es_url>`',
          kibanaUrlTemplate: '`<kibana_url>`'
        }
      })
    },
    DEB: {
      title: _i18n.i18n.translate('kbn.common.tutorials.metricbeatInstructions.config.debTitle', {
        defaultMessage: 'Edit the configuration'
      }),
      textPre: _i18n.i18n.translate('kbn.common.tutorials.metricbeatInstructions.config.debTextPre', {
        defaultMessage: 'Modify {path} to set the connection information:',
        values: {
          path: '`/etc/metricbeat/metricbeat.yml`'
        }
      }),
      commands: ['output.elasticsearch:', '  hosts: ["<es_url>"]', '  username: "elastic"', '  password: "<password>"', 'setup.kibana:', '  host: "<kibana_url>"', (0, _get_space_id_for_beats_tutorial.getSpaceIdForBeatsTutorial)(context)],
      textPost: _i18n.i18n.translate('kbn.common.tutorials.metricbeatInstructions.config.debTextPost', {
        defaultMessage: 'Where {passwordTemplate} is the password of the `elastic` user, {esUrlTemplate} is the URL of Elasticsearch, \
and {kibanaUrlTemplate} is the URL of Kibana.',
        values: {
          passwordTemplate: '`<password>`',
          esUrlTemplate: '`<es_url>`',
          kibanaUrlTemplate: '`<kibana_url>`'
        }
      })
    },
    RPM: {
      title: _i18n.i18n.translate('kbn.common.tutorials.metricbeatInstructions.config.rpmTitle', {
        defaultMessage: 'Edit the configuration'
      }),
      textPre: _i18n.i18n.translate('kbn.common.tutorials.metricbeatInstructions.config.rpmTextPre', {
        defaultMessage: 'Modify {path} to set the connection information:',
        values: {
          path: '`/etc/metricbeat/metricbeat.yml`'
        }
      }),
      commands: ['output.elasticsearch:', '  hosts: ["<es_url>"]', '  username: "elastic"', '  password: "<password>"', 'setup.kibana:', '  host: "<kibana_url>"', (0, _get_space_id_for_beats_tutorial.getSpaceIdForBeatsTutorial)(context)],
      textPost: _i18n.i18n.translate('kbn.common.tutorials.metricbeatInstructions.config.rpmTextPost', {
        defaultMessage: 'Where {passwordTemplate} is the password of the `elastic` user, {esUrlTemplate} is the URL of Elasticsearch, \
and {kibanaUrlTemplate} is the URL of Kibana.',
        values: {
          passwordTemplate: '`<password>`',
          esUrlTemplate: '`<es_url>`',
          kibanaUrlTemplate: '`<kibana_url>`'
        }
      })
    },
    WINDOWS: {
      title: _i18n.i18n.translate('kbn.common.tutorials.metricbeatInstructions.config.windowsTitle', {
        defaultMessage: 'Edit the configuration'
      }),
      textPre: _i18n.i18n.translate('kbn.common.tutorials.metricbeatInstructions.config.windowsTextPre', {
        defaultMessage: 'Modify {path} to set the connection information:',
        values: {
          path: '`C:\\Program Files\\Metricbeat\\metricbeat.yml`'
        }
      }),
      commands: ['output.elasticsearch:', '  hosts: ["<es_url>"]', '  username: "elastic"', '  password: "<password>"', 'setup.kibana:', '  host: "<kibana_url>"', (0, _get_space_id_for_beats_tutorial.getSpaceIdForBeatsTutorial)(context)],
      textPost: _i18n.i18n.translate('kbn.common.tutorials.metricbeatInstructions.config.windowsTextPost', {
        defaultMessage: 'Where {passwordTemplate} is the password of the `elastic` user, {esUrlTemplate} is the URL of Elasticsearch, \
and {kibanaUrlTemplate} is the URL of Kibana.',
        values: {
          passwordTemplate: '`<password>`',
          esUrlTemplate: '`<es_url>`',
          kibanaUrlTemplate: '`<kibana_url>`'
        }
      })
    }
  }
});

const createMetricbeatCloudInstructions = exports.createMetricbeatCloudInstructions = () => ({
  CONFIG: {
    OSX: {
      title: _i18n.i18n.translate('kbn.common.tutorials.metricbeatCloudInstructions.config.osxTitle', {
        defaultMessage: 'Edit the configuration'
      }),
      textPre: _i18n.i18n.translate('kbn.common.tutorials.metricbeatCloudInstructions.config.osxTextPre', {
        defaultMessage: 'Modify {path} to set the connection information for Elastic Cloud:',
        values: {
          path: '`metricbeat.yml`'
        }
      }),
      commands: ['cloud.id: "{config.cloud.id}"', 'cloud.auth: "elastic:<password>"'],
      textPost: _i18n.i18n.translate('kbn.common.tutorials.metricbeatCloudInstructions.config.osxTextPost', {
        defaultMessage: 'Where {passwordTemplate} is the password of the `elastic` user.',
        values: { passwordTemplate: '`<password>`' }
      })
    },
    DEB: {
      title: _i18n.i18n.translate('kbn.common.tutorials.metricbeatCloudInstructions.config.debTitle', {
        defaultMessage: 'Edit the configuration'
      }),
      textPre: _i18n.i18n.translate('kbn.common.tutorials.metricbeatCloudInstructions.config.debTextPre', {
        defaultMessage: 'Modify {path} to set the connection information for Elastic Cloud:',
        values: {
          path: '`/etc/metricbeat/metricbeat.yml`'
        }
      }),
      commands: ['cloud.id: "{config.cloud.id}"', 'cloud.auth: "elastic:<password>"'],
      textPost: _i18n.i18n.translate('kbn.common.tutorials.metricbeatCloudInstructions.config.debTextPost', {
        defaultMessage: 'Where {passwordTemplate} is the password of the `elastic` user.',
        values: { passwordTemplate: '`<password>`' }
      })
    },
    RPM: {
      title: _i18n.i18n.translate('kbn.common.tutorials.metricbeatCloudInstructions.config.rpmTitle', {
        defaultMessage: 'Edit the configuration'
      }),
      textPre: _i18n.i18n.translate('kbn.common.tutorials.metricbeatCloudInstructions.config.rpmTextPre', {
        defaultMessage: 'Modify {path} to set the connection information for Elastic Cloud:',
        values: {
          path: '`/etc/metricbeat/metricbeat.yml`'
        }
      }),
      commands: ['cloud.id: "{config.cloud.id}"', 'cloud.auth: "elastic:<password>"'],
      textPost: _i18n.i18n.translate('kbn.common.tutorials.metricbeatCloudInstructions.config.rpmTextPost', {
        defaultMessage: 'Where {passwordTemplate} is the password of the `elastic` user.',
        values: { passwordTemplate: '`<password>`' }
      })
    },
    WINDOWS: {
      title: _i18n.i18n.translate('kbn.common.tutorials.metricbeatCloudInstructions.config.windowsTitle', {
        defaultMessage: 'Edit the configuration'
      }),
      textPre: _i18n.i18n.translate('kbn.common.tutorials.metricbeatCloudInstructions.config.windowsTextPre', {
        defaultMessage: 'Modify {path} to set the connection information for Elastic Cloud:',
        values: {
          path: '`C:\\Program Files\\Metricbeat\\metricbeat.yml`'
        }
      }),
      commands: ['cloud.id: "{config.cloud.id}"', 'cloud.auth: "elastic:<password>"'],
      textPost: _i18n.i18n.translate('kbn.common.tutorials.metricbeatCloudInstructions.config.windowsTextPost', {
        defaultMessage: 'Where {passwordTemplate} is the password of the `elastic` user.',
        values: { passwordTemplate: '`<password>`' }
      })
    }
  }
});

function metricbeatEnableInstructions(moduleName) {
  return {
    OSX: {
      title: _i18n.i18n.translate('kbn.common.tutorials.metricbeatEnableInstructions.osxTitle', {
        defaultMessage: 'Enable and configure the {moduleName} module',
        values: { moduleName }
      }),
      textPre: _i18n.i18n.translate('kbn.common.tutorials.metricbeatEnableInstructions.osxTextPre', {
        defaultMessage: 'From the installation directory, run:'
      }),
      commands: ['./metricbeat modules enable ' + moduleName],
      textPost: _i18n.i18n.translate('kbn.common.tutorials.metricbeatEnableInstructions.osxTextPost', {
        defaultMessage: 'Modify the settings in the `modules.d/{moduleName}.yml` file.',
        values: { moduleName }
      })
    },
    DEB: {
      title: _i18n.i18n.translate('kbn.common.tutorials.metricbeatEnableInstructions.debTitle', {
        defaultMessage: 'Enable and configure the {moduleName} module',
        values: { moduleName }
      }),
      commands: ['sudo metricbeat modules enable ' + moduleName],
      textPost: _i18n.i18n.translate('kbn.common.tutorials.metricbeatEnableInstructions.debTextPost', {
        defaultMessage: 'Modify the settings in the `/etc/metricbeat/modules.d/{moduleName}.yml` file.',
        values: { moduleName }
      })
    },
    RPM: {
      title: _i18n.i18n.translate('kbn.common.tutorials.metricbeatEnableInstructions.rpmTitle', {
        defaultMessage: 'Enable and configure the {moduleName} module',
        values: { moduleName }
      }),
      commands: ['sudo metricbeat modules enable ' + moduleName],
      textPost: _i18n.i18n.translate('kbn.common.tutorials.metricbeatEnableInstructions.rpmTextPost', {
        defaultMessage: 'Modify the settings in the `/etc/metricbeat/modules.d/{moduleName}.yml` file.',
        values: { moduleName }
      })
    },
    WINDOWS: {
      title: _i18n.i18n.translate('kbn.common.tutorials.metricbeatEnableInstructions.windowsTitle', {
        defaultMessage: 'Enable and configure the {moduleName} module',
        values: { moduleName }
      }),
      textPre: _i18n.i18n.translate('kbn.common.tutorials.metricbeatEnableInstructions.windowsTextPre', {
        defaultMessage: 'From the {path} folder, run:',
        values: { path: `C:\\Program Files\\Metricbeat` }
      }),
      commands: ['.\\metricbeat.exe modules enable ' + moduleName],
      textPost: _i18n.i18n.translate('kbn.common.tutorials.metricbeatEnableInstructions.windowsTextPost', {
        defaultMessage: 'Modify the settings in the `modules.d/{moduleName}.yml` file.',
        values: { moduleName }
      })
    }
  };
}

function metricbeatStatusCheck(moduleName) {
  return {
    title: _i18n.i18n.translate('kbn.common.tutorials.metricbeatStatusCheck.title', {
      defaultMessage: 'Module status'
    }),
    text: _i18n.i18n.translate('kbn.common.tutorials.metricbeatStatusCheck.text', {
      defaultMessage: 'Check that data is received from the Metricbeat `{moduleName}` module',
      values: { moduleName }
    }),
    btnLabel: _i18n.i18n.translate('kbn.common.tutorials.metricbeatStatusCheck.buttonLabel', {
      defaultMessage: 'Check data'
    }),
    success: _i18n.i18n.translate('kbn.common.tutorials.metricbeatStatusCheck.successText', {
      defaultMessage: 'Data successfully received from this module'
    }),
    error: _i18n.i18n.translate('kbn.common.tutorials.metricbeatStatusCheck.errorText', {
      defaultMessage: 'No data has been received from this module yet'
    }),
    esHitsCheck: {
      index: 'metricbeat-*',
      query: {
        bool: {
          filter: {
            term: {
              'metricset.module': moduleName
            }
          }
        }
      }
    }
  };
}

function onPremInstructions(moduleName, platforms, context) {
  const METRICBEAT_INSTRUCTIONS = createMetricbeatInstructions(context);

  return {
    instructionSets: [{
      title: _i18n.i18n.translate('kbn.common.tutorials.metricbeat.premInstructions.gettingStarted.title', {
        defaultMessage: 'Getting Started'
      }),
      instructionVariants: [{
        id: _instruction_variant.INSTRUCTION_VARIANT.OSX,
        instructions: [METRICBEAT_INSTRUCTIONS.INSTALL.OSX, METRICBEAT_INSTRUCTIONS.CONFIG.OSX, metricbeatEnableInstructions(moduleName).OSX, METRICBEAT_INSTRUCTIONS.START.OSX]
      }, {
        id: _instruction_variant.INSTRUCTION_VARIANT.DEB,
        instructions: [METRICBEAT_INSTRUCTIONS.INSTALL.DEB, METRICBEAT_INSTRUCTIONS.CONFIG.DEB, metricbeatEnableInstructions(moduleName).DEB, METRICBEAT_INSTRUCTIONS.START.DEB]
      }, {
        id: _instruction_variant.INSTRUCTION_VARIANT.RPM,
        instructions: [METRICBEAT_INSTRUCTIONS.INSTALL.RPM, METRICBEAT_INSTRUCTIONS.CONFIG.RPM, metricbeatEnableInstructions(moduleName).RPM, METRICBEAT_INSTRUCTIONS.START.RPM]
      }, {
        id: _instruction_variant.INSTRUCTION_VARIANT.WINDOWS,
        instructions: [METRICBEAT_INSTRUCTIONS.INSTALL.WINDOWS, METRICBEAT_INSTRUCTIONS.CONFIG.WINDOWS, metricbeatEnableInstructions(moduleName).WINDOWS, METRICBEAT_INSTRUCTIONS.START.WINDOWS]
      }],
      statusCheck: metricbeatStatusCheck(moduleName)
    }]
  };
}

function onPremCloudInstructions(moduleName) {
  const TRYCLOUD_OPTION1 = (0, _onprem_cloud_instructions.createTrycloudOption1)();
  const TRYCLOUD_OPTION2 = (0, _onprem_cloud_instructions.createTrycloudOption2)();
  const METRICBEAT_INSTRUCTIONS = createMetricbeatInstructions();

  return {
    instructionSets: [{
      title: _i18n.i18n.translate('kbn.common.tutorials.metricbeat.premCloudInstructions.gettingStarted.title', {
        defaultMessage: 'Getting Started'
      }),
      instructionVariants: [{
        id: _instruction_variant.INSTRUCTION_VARIANT.OSX,
        instructions: [TRYCLOUD_OPTION1, TRYCLOUD_OPTION2, METRICBEAT_INSTRUCTIONS.INSTALL.OSX, METRICBEAT_INSTRUCTIONS.CONFIG.OSX, metricbeatEnableInstructions(moduleName).OSX, METRICBEAT_INSTRUCTIONS.START.OSX]
      }, {
        id: _instruction_variant.INSTRUCTION_VARIANT.DEB,
        instructions: [TRYCLOUD_OPTION1, TRYCLOUD_OPTION2, METRICBEAT_INSTRUCTIONS.INSTALL.DEB, METRICBEAT_INSTRUCTIONS.CONFIG.DEB, metricbeatEnableInstructions(moduleName).DEB, METRICBEAT_INSTRUCTIONS.START.DEB]
      }, {
        id: _instruction_variant.INSTRUCTION_VARIANT.RPM,
        instructions: [TRYCLOUD_OPTION1, TRYCLOUD_OPTION2, METRICBEAT_INSTRUCTIONS.INSTALL.RPM, METRICBEAT_INSTRUCTIONS.CONFIG.RPM, metricbeatEnableInstructions(moduleName).RPM, METRICBEAT_INSTRUCTIONS.START.RPM]
      }, {
        id: _instruction_variant.INSTRUCTION_VARIANT.WINDOWS,
        instructions: [TRYCLOUD_OPTION1, TRYCLOUD_OPTION2, METRICBEAT_INSTRUCTIONS.INSTALL.WINDOWS, METRICBEAT_INSTRUCTIONS.CONFIG.WINDOWS, metricbeatEnableInstructions(moduleName).WINDOWS, METRICBEAT_INSTRUCTIONS.START.WINDOWS]
      }],
      statusCheck: metricbeatStatusCheck(moduleName)
    }]
  };
}

function cloudInstructions(moduleName) {
  const METRICBEAT_INSTRUCTIONS = createMetricbeatInstructions();
  const METRICBEAT_CLOUD_INSTRUCTIONS = createMetricbeatCloudInstructions();

  return {
    instructionSets: [{
      title: _i18n.i18n.translate('kbn.common.tutorials.metricbeat.cloudInstructions.gettingStarted.title', {
        defaultMessage: 'Getting Started'
      }),
      instructionVariants: [{
        id: _instruction_variant.INSTRUCTION_VARIANT.OSX,
        instructions: [METRICBEAT_INSTRUCTIONS.INSTALL.OSX, METRICBEAT_CLOUD_INSTRUCTIONS.CONFIG.OSX, metricbeatEnableInstructions(moduleName).OSX, METRICBEAT_INSTRUCTIONS.START.OSX]
      }, {
        id: _instruction_variant.INSTRUCTION_VARIANT.DEB,
        instructions: [METRICBEAT_INSTRUCTIONS.INSTALL.DEB, METRICBEAT_CLOUD_INSTRUCTIONS.CONFIG.DEB, metricbeatEnableInstructions(moduleName).DEB, METRICBEAT_INSTRUCTIONS.START.DEB]
      }, {
        id: _instruction_variant.INSTRUCTION_VARIANT.RPM,
        instructions: [METRICBEAT_INSTRUCTIONS.INSTALL.RPM, METRICBEAT_CLOUD_INSTRUCTIONS.CONFIG.RPM, metricbeatEnableInstructions(moduleName).RPM, METRICBEAT_INSTRUCTIONS.START.RPM]
      }, {
        id: _instruction_variant.INSTRUCTION_VARIANT.WINDOWS,
        instructions: [METRICBEAT_INSTRUCTIONS.INSTALL.WINDOWS, METRICBEAT_CLOUD_INSTRUCTIONS.CONFIG.WINDOWS, metricbeatEnableInstructions(moduleName).WINDOWS, METRICBEAT_INSTRUCTIONS.START.WINDOWS]
      }],
      statusCheck: metricbeatStatusCheck(moduleName)
    }]
  };
}