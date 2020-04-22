'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports._getFilePath = _getFilePath;
exports._checkFilePathDeprecation = _checkFilePathDeprecation;
exports._downloadSingle = _downloadSingle;
exports.download = download;

var _http = require('./downloaders/http');

var _http2 = _interopRequireDefault(_http);

var _file = require('./downloaders/file');

var _file2 = _interopRequireDefault(_file);

var _errors = require('../lib/errors');

var _url = require('url');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

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

function _isWindows() {
  return (/^win/.test(process.platform)
  );
}

function _getFilePath(filePath) {
  const decodedPath = decodeURI(filePath);
  const prefixedDrive = /^\/[a-zA-Z]:/.test(decodedPath);
  if (_isWindows() && prefixedDrive) {
    return decodedPath.slice(1);
  }

  return decodedPath;
}

function _checkFilePathDeprecation(sourceUrl, logger) {
  const twoSlashes = /^file:\/\/(?!\/)/.test(sourceUrl);
  if (_isWindows() && twoSlashes) {
    logger.log('Install paths with file:// are deprecated, use file:/// instead');
  }
}

function _downloadSingle(settings, logger, sourceUrl) {
  const urlInfo = (0, _url.parse)(sourceUrl);
  let downloadPromise;

  if (/^file/.test(urlInfo.protocol)) {
    _checkFilePathDeprecation(sourceUrl, logger);
    downloadPromise = (0, _file2.default)(logger, _getFilePath(urlInfo.path, sourceUrl), settings.tempArchiveFile);
  } else if (/^https?/.test(urlInfo.protocol)) {
    downloadPromise = (0, _http2.default)(logger, sourceUrl, settings.tempArchiveFile, settings.timeout);
  } else {
    downloadPromise = Promise.reject(new _errors.UnsupportedProtocolError());
  }

  return downloadPromise;
}

//Attempts to download each url in turn until one is successful
function download(settings, logger) {
  const urls = settings.urls.slice(0);

  function tryNext() {
    const sourceUrl = urls.shift();
    if (!sourceUrl) {
      throw new Error('No valid url specified.');
    }

    logger.log(`Attempting to transfer from ${sourceUrl}`);

    return _downloadSingle(settings, logger, sourceUrl).catch(err => {
      const isUnsupportedProtocol = err instanceof _errors.UnsupportedProtocolError;
      const isDownloadResourceNotFound = err.message === 'ENOTFOUND';
      if (isUnsupportedProtocol || isDownloadResourceNotFound) {
        return tryNext();
      }
      throw err;
    });
  }

  return tryNext();
}