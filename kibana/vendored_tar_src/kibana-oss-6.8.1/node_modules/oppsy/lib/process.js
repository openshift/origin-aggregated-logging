'use strict';

// Load modules

const Hoek = require('hoek');
const Utils = require('./utils');

// Declare internals

const internals = {};


module.exports = internals;


internals.delay = () => {

    const bench = new Hoek.Bench();

    return new Promise((resolve) => {

        setImmediate(() => {

            return resolve(bench.elapsed());
        });
    });
};


internals.uptime = Utils.resolveNextTick(process.uptime);


internals.memoryUsage = Utils.resolveNextTick(process.memoryUsage);

internals.cpuUsage = Utils.resolveNextTick(process.cpuUsage);
