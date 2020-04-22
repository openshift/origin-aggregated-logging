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
import * as tslib_1 from "tslib";
import { EventEmitter } from 'events';
import $ from 'jquery';
import { isEqual } from 'lodash';
import ResizeObserver from 'resize-observer-polyfill';
function validateElArg(el) {
    // the ResizeChecker historically accepted jquery elements,
    // so we wrap in jQuery then extract the element
    var $el = $(el);
    if ($el.length !== 1) {
        throw new TypeError('ResizeChecker must be constructed with a single DOM element.');
    }
    return $el.get(0);
}
function getSize(el) {
    return [el.clientWidth, el.clientHeight];
}
/**
 *  ResizeChecker receives an element and emits a "resize" event every time it changes size.
 */
var ResizeChecker = /** @class */ (function (_super) {
    tslib_1.__extends(ResizeChecker, _super);
    function ResizeChecker(el, args) {
        if (args === void 0) { args = {}; }
        var _this = _super.call(this) || this;
        _this.destroyed = false;
        _this.expectedSize = null;
        _this.el = validateElArg(el);
        _this.observer = new ResizeObserver(function () {
            if (_this.expectedSize) {
                var sameSize = isEqual(getSize(el), _this.expectedSize);
                _this.expectedSize = null;
                if (sameSize) {
                    // don't trigger resize notification if the size is what we expect
                    return;
                }
            }
            _this.emit('resize');
        });
        // Only enable the checker immediately if args.disabled wasn't set to true
        if (!args.disabled) {
            _this.enable();
        }
        return _this;
    }
    ResizeChecker.prototype.enable = function () {
        if (this.destroyed) {
            // Don't allow enabling an already destroyed resize checker
            return;
        }
        // the width and height of the element that we expect to see
        // on the next resize notification. If it matches the size at
        // the time of starting observing then it we will be ignored.
        // We know that observer and el are not null since we are not yet destroyed.
        this.expectedSize = getSize(this.el);
        this.observer.observe(this.el);
    };
    /**
     *  Run a function and ignore all resizes that occur
     *  while it's running.
     */
    ResizeChecker.prototype.modifySizeWithoutTriggeringResize = function (block) {
        try {
            block();
        }
        finally {
            if (this.el) {
                this.expectedSize = getSize(this.el);
            }
        }
    };
    /**
     * Tell the ResizeChecker to shutdown, stop listenings, and never
     * emit another resize event.
     *
     * Cleans up it's listeners and timers.
     */
    ResizeChecker.prototype.destroy = function () {
        if (this.destroyed) {
            return;
        }
        this.destroyed = true;
        this.observer.disconnect();
        this.observer = null;
        this.expectedSize = null;
        this.el = null;
        this.removeAllListeners();
    };
    return ResizeChecker;
}(EventEmitter));
export { ResizeChecker };
