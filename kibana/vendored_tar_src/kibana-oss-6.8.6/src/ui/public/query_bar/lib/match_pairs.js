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
 * This helper automatically handles matching pairs.
 * Specifically, it does the following:
 *
 * 1. If the key is a closer, and the character in front of the cursor is the
 *    same, simply move the cursor forward.
 * 2. If the key is an opener, insert the opener at the beginning of the
 *    selection, and the closer at the end of the selection, and move the
 *    selection forward.
 * 3. If the backspace is hit, and the characters before and after the cursor
 *    are a pair, remove both characters and move the cursor backward.
 */
var pairs = ['()', '[]', '{}', "''", '""'];
var openers = pairs.map(function (pair) { return pair[0]; });
var closers = pairs.map(function (pair) { return pair[1]; });
export function matchPairs(_a) {
    var value = _a.value, selectionStart = _a.selectionStart, selectionEnd = _a.selectionEnd, key = _a.key, metaKey = _a.metaKey, updateQuery = _a.updateQuery, preventDefault = _a.preventDefault;
    if (shouldMoveCursorForward(key, value, selectionStart, selectionEnd)) {
        preventDefault();
        updateQuery(value, selectionStart + 1, selectionEnd + 1);
    }
    else if (shouldInsertMatchingCloser(key, value, selectionStart, selectionEnd)) {
        preventDefault();
        var newValue = value.substr(0, selectionStart) +
            key +
            value.substring(selectionStart, selectionEnd) +
            closers[openers.indexOf(key)] +
            value.substr(selectionEnd);
        updateQuery(newValue, selectionStart + 1, selectionEnd + 1);
    }
    else if (shouldRemovePair(key, metaKey, value, selectionStart, selectionEnd)) {
        preventDefault();
        var newValue = value.substr(0, selectionEnd - 1) + value.substr(selectionEnd + 1);
        updateQuery(newValue, selectionStart - 1, selectionEnd - 1);
    }
}
function shouldMoveCursorForward(key, value, selectionStart, selectionEnd) {
    if (!closers.includes(key)) {
        return false;
    }
    // Never move selection forward for multi-character selections
    if (selectionStart !== selectionEnd) {
        return false;
    }
    // Move selection forward if the key is the same as the closer in front of the selection
    return value.charAt(selectionEnd) === key;
}
function shouldInsertMatchingCloser(key, value, selectionStart, selectionEnd) {
    if (!openers.includes(key)) {
        return false;
    }
    // Always insert for multi-character selections
    if (selectionStart !== selectionEnd) {
        return true;
    }
    var precedingCharacter = value.charAt(selectionStart - 1);
    var followingCharacter = value.charAt(selectionStart + 1);
    // Don't insert if the preceding character is a backslash
    if (precedingCharacter === '\\') {
        return false;
    }
    // Don't insert if it's a quote and the either of the preceding/following characters is alphanumeric
    return !(['"', "'"].includes(key) &&
        (isAlphanumeric(precedingCharacter) || isAlphanumeric(followingCharacter)));
}
function shouldRemovePair(key, metaKey, value, selectionStart, selectionEnd) {
    if (key !== 'Backspace' || metaKey) {
        return false;
    }
    // Never remove for multi-character selections
    if (selectionStart !== selectionEnd) {
        return false;
    }
    // Remove if the preceding/following characters are a pair
    return pairs.includes(value.substr(selectionEnd - 1, 2));
}
function isAlphanumeric(value) {
    if (value === void 0) { value = ''; }
    return value.match(/[a-zA-Z0-9_]/);
}
