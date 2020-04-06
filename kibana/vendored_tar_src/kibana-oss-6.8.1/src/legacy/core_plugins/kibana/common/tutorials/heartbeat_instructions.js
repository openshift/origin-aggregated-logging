'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.createHeartbeatCloudInstructions = exports.createHeartbeatInstructions = undefined;
exports.heartbeatEnableInstructionsOnPrem = heartbeatEnableInstructionsOnPrem;
exports.heartbeatEnableInstructionsCloud = heartbeatEnableInstructionsCloud;
exports.heartbeatStatusCheck = heartbeatStatusCheck;
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

const createHeartbeatInstructions = exports.createHeartbeatInstructions = context => ({
  INSTALL: {
    OSX: {
      title: _i18n.i18n.translate('kbn.common.tutorials.heartbeatInstructions.install.osxTitle', {
        defaultMessage: 'Download and install Heartbeat'
      }),
      textPre: _i18n.i18n.translate('kbn.common.tutorials.heartbeatInstructions.install.osxTextPre', {
        defaultMessage: 'First time using Heartbeat? See the [Getting Started Guide]({link}).',
        values: { link: '{config.docs.beats.heartbeat}/heartbeat-getting-started.html' }
      }),
      commands: ['curl -L -O https://artifacts.elastic.co/downloads/beats/heartbeat/heartbeat-{config.kibana.version}-darwin-x86_64.tar.gz', 'tar xzvf heartbeat-{config.kibana.version}-darwin-x86_64.tar.gz', 'cd heartbeat-{config.kibana.version}-darwin-x86_64/']
    },
    DEB: {
      title: _i18n.i18n.translate('kbn.common.tutorials.heartbeatInstructions.install.debTitle', {
        defaultMessage: 'Download and install Heartbeat'
      }),
      textPre: _i18n.i18n.translate('kbn.common.tutorials.heartbeatInstructions.install.debTextPre', {
        defaultMessage: 'First time using Heartbeat? See the [Getting Started Guide]({link}).',
        values: { link: '{config.docs.beats.heartbeat}/heartbeat-getting-started.html' }
      }),
      commands: ['curl -L -O https://artifacts.elastic.co/downloads/beats/heartbeat/heartbeat-{config.kibana.version}-amd64.deb', 'sudo dpkg -i heartbeat-{config.kibana.version}-amd64.deb'],
      textPost: _i18n.i18n.translate('kbn.common.tutorials.heartbeatInstructions.install.debTextPost', {
        defaultMessage: 'Looking for the 32-bit packages? See the [Download page]({link}).',
        values: { link: 'https://www.elastic.co/downloads/beats/heartbeat' }
      })
    },
    RPM: {
      title: _i18n.i18n.translate('kbn.common.tutorials.heartbeatInstructions.install.rpmTitle', {
        defaultMessage: 'Download and install Heartbeat'
      }),
      textPre: _i18n.i18n.translate('kbn.common.tutorials.heartbeatInstructions.install.rpmTextPre', {
        defaultMessage: 'First time using Heartbeat? See the [Getting Started Guide]({link}).',
        values: { link: '{config.docs.beats.heartbeat}/heartbeat-getting-started.html' }
      }),
      commands: ['curl -L -O https://artifacts.elastic.co/downloads/beats/heartbeat/heartbeat-{config.kibana.version}-x86_64.rpm', 'sudo rpm -vi heartbeat-{config.kibana.version}-x86_64.rpm'],
      textPost: _i18n.i18n.translate('kbn.common.tutorials.heartbeatInstructions.install.debTextPost', {
        defaultMessage: 'Looking for the 32-bit packages? See the [Download page]({link}).',
        values: { link: 'https://www.elastic.co/downloads/beats/heartbeat' }
      })
    },
    WINDOWS: {
      title: _i18n.i18n.translate('kbn.common.tutorials.heartbeatInstructions.install.windowsTitle', {
        defaultMessage: 'Download and install Heartbeat'
      }),
      textPre: _i18n.i18n.translate('kbn.common.tutorials.heartbeatInstructions.install.windowsTextPre', {
        defaultMessage: 'First time using Heartbeat? See the [Getting Started Guide]({heartbeatLink}).\n\
 1. Download the Heartbeat Windows zip file from the [Download]({elasticLink}) page.\n\
 2. Extract the contents of the zip file into {folderPath}.\n\
 3. Rename the {directoryName} directory to `Heartbeat`.\n\
 4. Open a PowerShell prompt as an Administrator (right-click the PowerShell icon and select \
**Run As Administrator**). If you are running Windows XP, you might need to download and install PowerShell.\n\
 5. From the PowerShell prompt, run the following commands to install Heartbeat as a Windows service.',
        values: {
          directoryName: '`heartbeat-{config.kibana.version}-windows`',
          folderPath: '`C:\\Program Files`',
          heartbeatLink: '{config.docs.beats.heartbeat}/heartbeat-getting-started.html',
          elasticLink: 'https://www.elastic.co/downloads/beats/heartbeat'
        }
      }),
      commands: ['cd "C:\\Program Files\\Heartbeat"', '.\\install-service-heartbeat.ps1']
    }
  },
  START: {
    OSX: {
      title: _i18n.i18n.translate('kbn.common.tutorials.heartbeatInstructions.start.osxTitle', {
        defaultMessage: 'Start Heartbeat'
      }),
      textPre: _i18n.i18n.translate('kbn.common.tutorials.heartbeatInstructions.start.osxTextPre', {
        defaultMessage: 'The `setup` command loads the Kibana index pattern.'
      }),
      commands: ['./heartbeat setup', './heartbeat -e']
    },
    DEB: {
      title: _i18n.i18n.translate('kbn.common.tutorials.heartbeatInstructions.start.debTitle', {
        defaultMessage: 'Start Heartbeat'
      }),
      textPre: _i18n.i18n.translate('kbn.common.tutorials.heartbeatInstructions.start.debTextPre', {
        defaultMessage: 'The `setup` command loads the Kibana index pattern.'
      }),
      commands: ['sudo heartbeat setup', 'sudo service heartbeat-elastic start']
    },
    RPM: {
      title: _i18n.i18n.translate('kbn.common.tutorials.heartbeatInstructions.start.rpmTitle', {
        defaultMessage: 'Start Heartbeat'
      }),
      textPre: _i18n.i18n.translate('kbn.common.tutorials.heartbeatInstructions.start.rpmTextPre', {
        defaultMessage: 'The `setup` command loads the Kibana index pattern.'
      }),
      commands: ['sudo heartbeat setup', 'sudo service heartbeat-elastic start']
    },
    WINDOWS: {
      title: _i18n.i18n.translate('kbn.common.tutorials.heartbeatInstructions.start.windowsTitle', {
        defaultMessage: 'Start Heartbeat'
      }),
      textPre: _i18n.i18n.translate('kbn.common.tutorials.heartbeatInstructions.start.windowsTextPre', {
        defaultMessage: 'The `setup` command loads the Kibana index pattern.'
      }),
      commands: ['.\\heartbeat.exe setup', 'Start-Service heartbeat']
    }
  },
  CONFIG: {
    OSX: {
      title: _i18n.i18n.translate('kbn.common.tutorials.heartbeatInstructions.config.osxTitle', {
        defaultMessage: 'Edit the configuration'
      }),
      textPre: _i18n.i18n.translate('kbn.common.tutorials.heartbeatInstructions.config.osxTextPre', {
        defaultMessage: 'Modify {path} to set the connection information:',
        values: {
          path: '`heartbeat.yml`'
        }
      }),
      commands: ['output.elasticsearch:', '  hosts: ["<es_url>"]', '  username: "elastic"', '  password: "<password>"', 'setup.kibana:', '  host: "<kibana_url>"', (0, _get_space_id_for_beats_tutorial.getSpaceIdForBeatsTutorial)(context)],
      textPost: _i18n.i18n.translate('kbn.common.tutorials.heartbeatInstructions.config.osxTextPost', {
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
      title: _i18n.i18n.translate('kbn.common.tutorials.heartbeatInstructions.config.debTitle', {
        defaultMessage: 'Edit the configuration'
      }),
      textPre: _i18n.i18n.translate('kbn.common.tutorials.heartbeatInstructions.config.debTextPre', {
        defaultMessage: 'Modify {path} to set the connection information:',
        values: {
          path: '`/etc/heartbeat/heartbeat.yml`'
        }
      }),
      commands: ['output.elasticsearch:', '  hosts: ["<es_url>"]', '  username: "elastic"', '  password: "<password>"', 'setup.kibana:', '  host: "<kibana_url>"', (0, _get_space_id_for_beats_tutorial.getSpaceIdForBeatsTutorial)(context)],
      textPost: _i18n.i18n.translate('kbn.common.tutorials.heartbeatInstructions.config.debTextPost', {
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
      title: _i18n.i18n.translate('kbn.common.tutorials.heartbeatInstructions.config.rpmTitle', {
        defaultMessage: 'Edit the configuration'
      }),
      textPre: _i18n.i18n.translate('kbn.common.tutorials.heartbeatInstructions.config.rpmTextPre', {
        defaultMessage: 'Modify {path} to set the connection information:',
        values: {
          path: '`/etc/heartbeat/heartbeat.yml`'
        }
      }),
      commands: ['output.elasticsearch:', '  hosts: ["<es_url>"]', '  username: "elastic"', '  password: "<password>"', 'setup.kibana:', '  host: "<kibana_url>"', (0, _get_space_id_for_beats_tutorial.getSpaceIdForBeatsTutorial)(context)],
      textPost: _i18n.i18n.translate('kbn.common.tutorials.heartbeatInstructions.config.rpmTextPost', {
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
      title: _i18n.i18n.translate('kbn.common.tutorials.heartbeatInstructions.config.windowsTitle', {
        defaultMessage: 'Edit the configuration'
      }),
      textPre: _i18n.i18n.translate('kbn.common.tutorials.heartbeatInstructions.config.windowsTextPre', {
        defaultMessage: 'Modify {path} to set the connection information:',
        values: {
          path: '`C:\\Program Files\\Heartbeat\\heartbeat.yml`'
        }
      }),
      commands: ['output.elasticsearch:', '  hosts: ["<es_url>"]', '  username: "elastic"', '  password: "<password>"', 'setup.kibana:', '  host: "<kibana_url>"', (0, _get_space_id_for_beats_tutorial.getSpaceIdForBeatsTutorial)(context)],
      textPost: _i18n.i18n.translate('kbn.common.tutorials.heartbeatInstructions.config.windowsTextPost', {
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

const createHeartbeatCloudInstructions = exports.createHeartbeatCloudInstructions = () => ({
  CONFIG: {
    OSX: {
      title: _i18n.i18n.translate('kbn.common.tutorials.heartbeatCloudInstructions.config.osxTitle', {
        defaultMessage: 'Edit the configuration'
      }),
      textPre: _i18n.i18n.translate('kbn.common.tutorials.heartbeatCloudInstructions.config.osxTextPre', {
        defaultMessage: 'Modify {path} to set the connection information for Elastic Cloud:',
        values: {
          path: '`heartbeat.yml`'
        }
      }),
      commands: ['cloud.id: "{config.cloud.id}"', 'cloud.auth: "elastic:<password>"'],
      textPost: _i18n.i18n.translate('kbn.common.tutorials.heartbeatCloudInstructions.config.osxTextPost', {
        defaultMessage: 'Where {passwordTemplate} is the password of the `elastic` user.',
        values: { passwordTemplate: '`<password>`' }
      })
    },
    DEB: {
      title: _i18n.i18n.translate('kbn.common.tutorials.heartbeatCloudInstructions.config.debTitle', {
        defaultMessage: 'Edit the configuration'
      }),
      textPre: _i18n.i18n.translate('kbn.common.tutorials.heartbeatCloudInstructions.config.debTextPre', {
        defaultMessage: 'Modify {path} to set the connection information for Elastic Cloud:',
        values: {
          path: '`/etc/heartbeat/heartbeat.yml`'
        }
      }),
      commands: ['cloud.id: "{config.cloud.id}"', 'cloud.auth: "elastic:<password>"'],
      textPost: _i18n.i18n.translate('kbn.common.tutorials.heartbeatCloudInstructions.config.debTextPost', {
        defaultMessage: 'Where {passwordTemplate} is the password of the `elastic` user.',
        values: { passwordTemplate: '`<password>`' }
      })
    },
    RPM: {
      title: _i18n.i18n.translate('kbn.common.tutorials.heartbeatCloudInstructions.config.rpmTitle', {
        defaultMessage: 'Edit the configuration'
      }),
      textPre: _i18n.i18n.translate('kbn.common.tutorials.heartbeatCloudInstructions.config.rpmTextPre', {
        defaultMessage: 'Modify {path} to set the connection information for Elastic Cloud:',
        values: {
          path: '`/etc/heartbeat/heartbeat.yml`'
        }
      }),
      commands: ['cloud.id: "{config.cloud.id}"', 'cloud.auth: "elastic:<password>"'],
      textPost: _i18n.i18n.translate('kbn.common.tutorials.heartbeatCloudInstructions.config.rpmTextPost', {
        defaultMessage: 'Where {passwordTemplate} is the password of the `elastic` user.',
        values: { passwordTemplate: '`<password>`' }
      })
    },
    WINDOWS: {
      title: _i18n.i18n.translate('kbn.common.tutorials.heartbeatCloudInstructions.config.windowsTitle', {
        defaultMessage: 'Edit the configuration'
      }),
      textPre: _i18n.i18n.translate('kbn.common.tutorials.heartbeatCloudInstructions.config.windowsTextPre', {
        defaultMessage: 'Modify {path} to set the connection information for Elastic Cloud:',
        values: {
          path: '`C:\\Program Files\\Heartbeat\\heartbeat.yml`'
        }
      }),
      commands: ['cloud.id: "{config.cloud.id}"', 'cloud.auth: "elastic:<password>"'],
      textPost: _i18n.i18n.translate('kbn.common.tutorials.heartbeatCloudInstructions.config.windowsTextPost', {
        defaultMessage: 'Where {passwordTemplate} is the password of the `elastic` user.',
        values: { passwordTemplate: '`<password>`' }
      })
    }
  }
});

function heartbeatEnableInstructionsOnPrem() {
  const defaultTitle = _i18n.i18n.translate('kbn.common.tutorials.heartbeatEnableOnPremInstructions.defaultTitle', {
    defaultMessage: 'Edit the configuration - Add monitors'
  });
  const defaultCommands = ['heartbeat.monitors:', '- type: http', '  urls: ["<http://localhost:9200>"]', '  schedule: "@every 10s"'];
  const defaultTextPost = _i18n.i18n.translate('kbn.common.tutorials.heartbeatEnableOnPremInstructions.defaultTextPost', {
    defaultMessage: 'Where {hostTemplate} is your monitored URL, For more details on how to configure Monitors in \
      Heartbeat, read the [Heartbeat configuration docs.]({configureLink})',
    values: {
      configureLink: '{config.docs.beats.heartbeat}/heartbeat-configuration.html',
      hostTemplate: '`<http://localhost:9200>`'
    }
  });
  return {
    OSX: {
      title: defaultTitle,
      textPre: _i18n.i18n.translate('kbn.common.tutorials.heartbeatEnableOnPremInstructions.osxTextPre', {
        defaultMessage: 'Edit the `heartbeat.monitors` setting in the `heartbeat.yml` file.'
      }),
      commands: defaultCommands,
      textPost: defaultTextPost
    },
    DEB: {
      title: defaultTitle,
      textPre: _i18n.i18n.translate('kbn.common.tutorials.heartbeatEnableOnPremInstructions.debTextPre', {
        defaultMessage: 'Edit the `heartbeat.monitors` setting in the `heartbeat.yml` file.'
      }),
      commands: defaultCommands,
      textPost: defaultTextPost
    },
    RPM: {
      title: defaultTitle,
      textPre: _i18n.i18n.translate('kbn.common.tutorials.heartbeatEnableOnPremInstructions.rpmTextPre', {
        defaultMessage: 'Edit the `heartbeat.monitors` setting in the `heartbeat.yml` file.'
      }),
      commands: defaultCommands,
      textPost: defaultTextPost
    },
    WINDOWS: {
      title: defaultTitle,
      textPre: _i18n.i18n.translate('kbn.common.tutorials.heartbeatEnableOnPremInstructions.windowsTextPre', {
        defaultMessage: 'Edit the `heartbeat.monitors` setting in the `heartbeat.yml` file.'
      }),
      commands: defaultCommands,
      textPost: defaultTextPost
    }
  };
}

function heartbeatEnableInstructionsCloud() {
  const defaultTitle = _i18n.i18n.translate('kbn.common.tutorials.heartbeatEnableCloudInstructions.defaultTitle', {
    defaultMessage: 'Edit the configuration - Add monitors'
  });
  const defaultCommands = ['heartbeat.monitors:', '- type: http', '  urls: ["http://elastic.co"]', '  schedule: "@every 10s"'];
  const defaultTextPost = _i18n.i18n.translate('kbn.common.tutorials.heartbeatEnableCloudInstructions.defaultTextPost', {
    defaultMessage: 'For more details on how to configure Monitors in Heartbeat, read the [Heartbeat configuration docs.]({configureLink})',
    values: { configureLink: '{config.docs.beats.heartbeat}/heartbeat-configuration.html' }
  });
  return {
    OSX: {
      title: defaultTitle,
      textPre: _i18n.i18n.translate('kbn.common.tutorials.heartbeatEnableCloudInstructions.osxTextPre', {
        defaultMessage: 'Edit the `heartbeat.monitors` setting in the `heartbeat.yml` file.'
      }),
      commands: defaultCommands,
      textPost: defaultTextPost
    },
    DEB: {
      title: defaultTitle,
      textPre: _i18n.i18n.translate('kbn.common.tutorials.heartbeatEnableCloudInstructions.debTextPre', {
        defaultMessage: 'Edit the `heartbeat.monitors` setting in the `heartbeat.yml` file.'
      }),
      commands: defaultCommands,
      textPost: defaultTextPost
    },
    RPM: {
      title: defaultTitle,
      textPre: _i18n.i18n.translate('kbn.common.tutorials.heartbeatEnableCloudInstructions.rpmTextPre', {
        defaultMessage: 'Edit the `heartbeat.monitors` setting in the `heartbeat.yml` file.'
      }),
      commands: defaultCommands,
      textPost: defaultTextPost
    },
    WINDOWS: {
      title: defaultTitle,
      textPre: _i18n.i18n.translate('kbn.common.tutorials.heartbeatEnableCloudInstructions.windowsTextPre', {
        defaultMessage: 'Edit the `heartbeat.monitors` setting in the `heartbeat.yml` file.'
      }),
      commands: defaultCommands,
      textPost: defaultTextPost
    }
  };
}

function heartbeatStatusCheck() {
  return {
    title: _i18n.i18n.translate('kbn.common.tutorials.heartbeatStatusCheck.title', {
      defaultMessage: 'Heartbeat status'
    }),
    text: _i18n.i18n.translate('kbn.common.tutorials.heartbeatStatusCheck.text', {
      defaultMessage: 'Check that data is received from Heartbeat'
    }),
    btnLabel: _i18n.i18n.translate('kbn.common.tutorials.heartbeatStatusCheck.buttonLabel', {
      defaultMessage: 'Check data'
    }),
    success: _i18n.i18n.translate('kbn.common.tutorials.heartbeatStatusCheck.successText', {
      defaultMessage: 'Data successfully received from Heartbeat'
    }),
    error: _i18n.i18n.translate('kbn.common.tutorials.heartbeatStatusCheck.errorText', {
      defaultMessage: 'No data has been received from Heartbeat yet'
    }),
    esHitsCheck: {
      index: 'heartbeat-*',
      query: {
        match_all: {}
      }
    }
  };
}

function onPremInstructions(platforms, context) {
  const HEARTBEAT_INSTRUCTIONS = createHeartbeatInstructions(context);

  return {
    instructionSets: [{
      title: _i18n.i18n.translate('kbn.common.tutorials.heartbeat.premInstructions.gettingStarted.title', {
        defaultMessage: 'Getting Started'
      }),
      instructionVariants: [{
        id: _instruction_variant.INSTRUCTION_VARIANT.OSX,
        instructions: [HEARTBEAT_INSTRUCTIONS.INSTALL.OSX, HEARTBEAT_INSTRUCTIONS.CONFIG.OSX, heartbeatEnableInstructionsOnPrem().OSX, HEARTBEAT_INSTRUCTIONS.START.OSX]
      }, {
        id: _instruction_variant.INSTRUCTION_VARIANT.DEB,
        instructions: [HEARTBEAT_INSTRUCTIONS.INSTALL.DEB, HEARTBEAT_INSTRUCTIONS.CONFIG.DEB, heartbeatEnableInstructionsOnPrem().DEB, HEARTBEAT_INSTRUCTIONS.START.DEB]
      }, {
        id: _instruction_variant.INSTRUCTION_VARIANT.RPM,
        instructions: [HEARTBEAT_INSTRUCTIONS.INSTALL.RPM, HEARTBEAT_INSTRUCTIONS.CONFIG.RPM, heartbeatEnableInstructionsOnPrem().RPM, HEARTBEAT_INSTRUCTIONS.START.RPM]
      }, {
        id: _instruction_variant.INSTRUCTION_VARIANT.WINDOWS,
        instructions: [HEARTBEAT_INSTRUCTIONS.INSTALL.WINDOWS, HEARTBEAT_INSTRUCTIONS.CONFIG.WINDOWS, heartbeatEnableInstructionsOnPrem().WINDOWS, HEARTBEAT_INSTRUCTIONS.START.WINDOWS]
      }],
      statusCheck: heartbeatStatusCheck()
    }]
  };
}

function onPremCloudInstructions() {
  const TRYCLOUD_OPTION1 = (0, _onprem_cloud_instructions.createTrycloudOption1)();
  const TRYCLOUD_OPTION2 = (0, _onprem_cloud_instructions.createTrycloudOption2)();
  const HEARTBEAT_INSTRUCTIONS = createHeartbeatInstructions();

  return {
    instructionSets: [{
      title: _i18n.i18n.translate('kbn.common.tutorials.heartbeat.premCloudInstructions.gettingStarted.title', {
        defaultMessage: 'Getting Started'
      }),
      instructionVariants: [{
        id: _instruction_variant.INSTRUCTION_VARIANT.OSX,
        instructions: [TRYCLOUD_OPTION1, TRYCLOUD_OPTION2, HEARTBEAT_INSTRUCTIONS.INSTALL.OSX, HEARTBEAT_INSTRUCTIONS.CONFIG.OSX, heartbeatEnableInstructionsCloud().OSX, HEARTBEAT_INSTRUCTIONS.START.OSX]
      }, {
        id: _instruction_variant.INSTRUCTION_VARIANT.DEB,
        instructions: [TRYCLOUD_OPTION1, TRYCLOUD_OPTION2, HEARTBEAT_INSTRUCTIONS.INSTALL.DEB, HEARTBEAT_INSTRUCTIONS.CONFIG.DEB, heartbeatEnableInstructionsCloud().DEB, HEARTBEAT_INSTRUCTIONS.START.DEB]
      }, {
        id: _instruction_variant.INSTRUCTION_VARIANT.RPM,
        instructions: [TRYCLOUD_OPTION1, TRYCLOUD_OPTION2, HEARTBEAT_INSTRUCTIONS.INSTALL.RPM, HEARTBEAT_INSTRUCTIONS.CONFIG.RPM, heartbeatEnableInstructionsCloud().RPM, HEARTBEAT_INSTRUCTIONS.START.RPM]
      }, {
        id: _instruction_variant.INSTRUCTION_VARIANT.WINDOWS,
        instructions: [TRYCLOUD_OPTION1, TRYCLOUD_OPTION2, HEARTBEAT_INSTRUCTIONS.INSTALL.WINDOWS, HEARTBEAT_INSTRUCTIONS.CONFIG.WINDOWS, heartbeatEnableInstructionsCloud().WINDOWS, HEARTBEAT_INSTRUCTIONS.START.WINDOWS]
      }],
      statusCheck: heartbeatStatusCheck()
    }]
  };
}

function cloudInstructions() {
  const HEARTBEAT_INSTRUCTIONS = createHeartbeatInstructions();
  const HEARTBEAT_CLOUD_INSTRUCTIONS = createHeartbeatCloudInstructions();

  return {
    instructionSets: [{
      title: _i18n.i18n.translate('kbn.common.tutorials.heartbeat.cloudInstructions.gettingStarted.title', {
        defaultMessage: 'Getting Started'
      }),
      instructionVariants: [{
        id: _instruction_variant.INSTRUCTION_VARIANT.OSX,
        instructions: [HEARTBEAT_INSTRUCTIONS.INSTALL.OSX, HEARTBEAT_CLOUD_INSTRUCTIONS.CONFIG.OSX, heartbeatEnableInstructionsCloud().OSX, HEARTBEAT_INSTRUCTIONS.START.OSX]
      }, {
        id: _instruction_variant.INSTRUCTION_VARIANT.DEB,
        instructions: [HEARTBEAT_INSTRUCTIONS.INSTALL.DEB, HEARTBEAT_CLOUD_INSTRUCTIONS.CONFIG.DEB, heartbeatEnableInstructionsCloud().DEB, HEARTBEAT_INSTRUCTIONS.START.DEB]
      }, {
        id: _instruction_variant.INSTRUCTION_VARIANT.RPM,
        instructions: [HEARTBEAT_INSTRUCTIONS.INSTALL.RPM, HEARTBEAT_CLOUD_INSTRUCTIONS.CONFIG.RPM, heartbeatEnableInstructionsCloud().RPM, HEARTBEAT_INSTRUCTIONS.START.RPM]
      }, {
        id: _instruction_variant.INSTRUCTION_VARIANT.WINDOWS,
        instructions: [HEARTBEAT_INSTRUCTIONS.INSTALL.WINDOWS, HEARTBEAT_CLOUD_INSTRUCTIONS.CONFIG.WINDOWS, heartbeatEnableInstructionsCloud().WINDOWS, HEARTBEAT_INSTRUCTIONS.START.WINDOWS]
      }],
      statusCheck: heartbeatStatusCheck()
    }]
  };
}