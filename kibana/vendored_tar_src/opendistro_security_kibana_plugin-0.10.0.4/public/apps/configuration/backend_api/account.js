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

import { uiModules } from 'ui/modules';
import { merge } from 'lodash';
import { uniq, cloneDeep } from 'lodash';
import client from './client';

/**
 * Account API client service.
 */
uiModules.get('apps/opendistro_security/configuration', [])
    .service('backendAccount', function (backendAPI) {
        const RESOURCE = 'account';

        this.fetch = () => {
            return backendAPI.list(RESOURCE);
        }

        this.save = (data) => {
            let dataToSave = cloneDeep(data);
            dataToSave = this.preSave(dataToSave);            
            return backendAPI.saveWithoutId(RESOURCE, dataToSave, false);
        };

        this.preSave = (user) => {
            delete user.hidden;
            delete user.reserved;
            delete user.static;
            delete user["password_confirmation"];
            return user;
        };

        this.postFetch = (user) => {
            delete user["hash"];
            user["current_password"] = "";
            user["password"] = "";
            user["password_confirmation"] = "";
            return user;
        };
    });