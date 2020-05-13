'use strict';

var _child_process = require('child_process');

var _commander = require('commander');

var _docs_repo = require('./docs_repo');

const cmd = new _commander.Command('node scripts/docs'); /*
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

cmd.option('--docrepo [path]', 'local path to the docs repo', (0, _docs_repo.defaultDocsRepoPath)()).option('--open', 'open the docs in the browser', false).parse(process.argv);

try {
  (0, _child_process.execFileSync)((0, _docs_repo.buildDocsScript)(cmd), (0, _docs_repo.buildDocsArgs)(cmd));
} catch (err) {
  if (err.code === 'ENOENT') {
    console.error(`elastic/docs repo must be cloned to ${cmd.docrepo}`);
  } else {
    console.error(err.stack);
  }

  process.exit(1);
}