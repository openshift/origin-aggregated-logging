"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
/**
 * Performs work on a scheduled interval, logging any errors. This waits for work to complete
 * (or error) prior to attempting another run.
 */
class TaskPoller {
    /**
     * Constructs a new TaskPoller.
     *
     * @param opts
     * @prop {number} pollInterval - How often, in milliseconds, we will run the work function
     * @prop {Logger} logger - The task manager logger
     * @prop {WorkFn} work - An empty, asynchronous function that performs the desired work
     */
    constructor(opts) {
        this.isStarted = false;
        this.isWorking = false;
        this.pollInterval = opts.pollInterval;
        this.logger = opts.logger;
        this.store = opts.store;
        this.work = opts.work;
    }
    /**
     * Starts the poller. If the poller is already running, this has no effect.
     */
    async start() {
        if (this.isStarted) {
            return;
        }
        if (!this.store.isInitialized) {
            await this.store.init();
        }
        this.isStarted = true;
        const poll = async () => {
            await this.attemptWork();
            if (this.isStarted) {
                this.timeout = setTimeout(poll, this.pollInterval);
            }
        };
        poll();
    }
    /**
     * Stops the poller.
     */
    stop() {
        this.isStarted = false;
        clearTimeout(this.timeout);
        this.timeout = undefined;
    }
    /**
     * Runs the work function. If the work function is currently running,
     * this has no effect.
     */
    async attemptWork() {
        if (!this.isStarted || this.isWorking) {
            return;
        }
        this.isWorking = true;
        try {
            await this.work();
        }
        catch (err) {
            this.logger.error(`Failed to poll for work: ${err}`);
        }
        finally {
            this.isWorking = false;
        }
    }
}
exports.TaskPoller = TaskPoller;
