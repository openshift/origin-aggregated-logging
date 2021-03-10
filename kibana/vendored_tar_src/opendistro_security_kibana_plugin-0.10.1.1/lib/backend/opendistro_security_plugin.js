/*
 * Copyright 2015-2018 _floragunn_ GmbH
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */
/*
 * Portions Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License").
 * You may not use this file except in compliance with the License.
 * A copy of the License is located at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * or in the "license" file accompanying this file. This file is distributed
 * on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
 * express or implied. See the License for the specific language governing
 * permissions and limitations under the License.
 */

/**
 * Security plugin extension for the Elasticsearch Javascript client.
 */

import util from 'util';

export default function (Client, config, components) {

    const ca = components.clientAction.factory;

    Client.prototype.opendistro_security = components.clientAction.namespaceFactory();

    Client.prototype.opendistro_security.prototype.authinfo = ca({
        url: {
            fmt: '/_opendistro/_security/authinfo'
        }
    });

    Client.prototype.opendistro_security.prototype.multitenancyinfo = ca({
        url: {
            fmt: '/_opendistro/_security/kibanainfo'
        }
    });

    Client.prototype.opendistro_security.prototype.tenantinfo = ca({
        url: {
            fmt: '/_opendistro/_security/tenantinfo'
        }
    });

    Client.prototype.opendistro_security.prototype.authtoken = ca({
        method: 'POST',
        needBody: true,
        url: {
            fmt: '/_opendistro/_security/api/authtoken'
        }
    });

};

