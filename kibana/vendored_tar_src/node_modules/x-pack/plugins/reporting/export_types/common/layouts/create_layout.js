"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const constants_1 = require("../constants");
const preserve_layout_1 = require("./preserve_layout");
const print_layout_1 = require("./print_layout");
function createLayout(server, layoutParams) {
    if (layoutParams && layoutParams.id === constants_1.LayoutTypes.PRESERVE_LAYOUT) {
        return new preserve_layout_1.PreserveLayout(layoutParams.dimensions);
    }
    // this is the default because some jobs won't have anything specified
    return new print_layout_1.PrintLayout(server);
}
exports.createLayout = createLayout;
