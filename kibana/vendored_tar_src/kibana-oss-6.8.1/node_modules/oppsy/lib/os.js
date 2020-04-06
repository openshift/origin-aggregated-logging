'use strict';

// Load modules

const Os = require('os');
const Utils = require('./utils');


// Declare internals

const internals = {};


module.exports = internals;

internals.mem = Utils.resolveNextTick(() => {

    return {
        total: Os.totalmem(),
        free: Os.freemem()
    };
});

internals.loadavg = Utils.resolveNextTick(Os.loadavg);

internals.uptime = Utils.resolveNextTick(Os.uptime);
