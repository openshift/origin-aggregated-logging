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
/**
 * The EmbeddableFactory creates and initializes an embeddable instance
 */
var EmbeddableFactory = /** @class */ (function () {
    /**
     *
     * @param name - a unique identified for this factory, which will be used to map an embeddable spec to
     * a factory that can generate an instance of it.
     */
    function EmbeddableFactory(_a) {
        var name = _a.name;
        this.name = name;
    }
    return EmbeddableFactory;
}());
export { EmbeddableFactory };
