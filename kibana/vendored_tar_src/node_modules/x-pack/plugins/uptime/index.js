"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const i18n_1 = require("@kbn/i18n");
const path_1 = require("path");
const constants_1 = require("./common/constants");
const server_1 = require("./server");
exports.uptime = (kibana) => new kibana.Plugin({
    configPrefix: 'xpack.uptime',
    id: constants_1.PLUGIN.ID,
    require: ['kibana', 'elasticsearch', 'xpack_main'],
    publicDir: path_1.resolve(__dirname, 'public'),
    uiExports: {
        app: {
            description: i18n_1.i18n.translate('xpack.uptime.pluginDescription', {
                defaultMessage: 'Uptime monitoring',
                description: 'The description text that will be shown to users in Kibana',
            }),
            icon: 'plugins/uptime/icons/heartbeat_white.svg',
            euiIconType: 'uptimeApp',
            title: i18n_1.i18n.translate('xpack.uptime.uptimeFeatureCatalogueTitle', {
                defaultMessage: 'Uptime',
            }),
            main: 'plugins/uptime/app',
            order: 8900,
            url: '/app/uptime#/',
        },
        home: ['plugins/uptime/register_feature'],
    },
    init(server) {
        server_1.initServerWithKibana(server);
    },
});
