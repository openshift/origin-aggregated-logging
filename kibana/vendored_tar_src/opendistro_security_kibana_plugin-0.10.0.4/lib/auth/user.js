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
 * Represents a Security user
 */
export default class User {

    /**
     * @property {string} username - The username.
     */
    get username() {
        return this._username;
    }

    /**
     * @property {Array} roles - The user roles.
     */
    get roles() {
        return this._roles;
    }

    /**
     * @property {Array} roles - The users unmapped backend roles.
     */
    get backendroles() {
        return this._backendroles;
    }

    /**
     * @property {Array} tenants - The user tenants.
     */
    get tenants() {
        return this._tenants;
    }

    /**
     * @property {Array} tenants - The user tenants.
     */
    get selectedTenant() {
        return this._selectedTenant;
    }
    /**
     * @property {object} credentials - The credentials that were used to authenticate the user.
     */
    get credentials() {
        return this._credentials;
    }

    /**
     * @property {object} proxyCredentials - User credentials to be used in requests to Elasticsearch performed by either the transport client
     * or the query engine.
     */
    get proxyCredentials() {
        return this._proxyCredentials;
    }

    constructor(username, credentials, proxyCredentials, roles, backendroles, tenants, selectedTenant) {
        this._username = username;
        this._credentials = credentials;
        this._proxyCredentials = proxyCredentials;
        this._roles = roles;
        this._selectedTenant = selectedTenant;
        this._backendroles = backendroles;
        this._tenants = tenants;
    }

}
