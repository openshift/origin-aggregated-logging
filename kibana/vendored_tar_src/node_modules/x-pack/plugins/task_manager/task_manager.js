"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const fill_pool_1 = require("./lib/fill_pool");
const logger_1 = require("./lib/logger");
const middleware_1 = require("./lib/middleware");
const sanitize_task_definitions_1 = require("./lib/sanitize_task_definitions");
const task_poller_1 = require("./task_poller");
const task_pool_1 = require("./task_pool");
const task_runner_1 = require("./task_runner");
const task_store_1 = require("./task_store");
/*
 * The TaskManager is the public interface into the task manager system. This glues together
 * all of the disparate modules in one integration point. The task manager operates in two different ways:
 *
 * - pre-init, it allows middleware registration, but disallows task manipulation
 * - post-init, it disallows middleware registration, but allows task manipulation
 *
 * Due to its complexity, this is mostly tested by integration tests (see readme).
 */
/**
 * The public interface into the task manager system.
 */
class TaskManager {
    /**
     * Initializes the task manager, preventing any further addition of middleware,
     * enabling the task manipulation methods, and beginning the background polling
     * mechanism.
     */
    constructor(kbnServer, server, config) {
        this.isInitialized = false;
        this.middleware = {
            beforeSave: async (saveOpts) => saveOpts,
            beforeRun: async (runOpts) => runOpts,
        };
        this.maxWorkers = config.get('xpack.task_manager.max_workers');
        this.overrideNumWorkers = config.get('xpack.task_manager.override_num_workers');
        this.definitions = {};
        const logger = new logger_1.TaskManagerLogger((...args) => server.log(...args));
        /* Kibana UUID needs to be pulled live (not cached), as it takes a long time
         * to initialize, and can change after startup */
        const store = new task_store_1.TaskStore({
            callCluster: server.plugins.elasticsearch.getCluster('admin').callWithInternalUser,
            index: config.get('xpack.task_manager.index'),
            maxAttempts: config.get('xpack.task_manager.max_attempts'),
            supportedTypes: Object.keys(this.definitions),
            logger,
            getKibanaUuid: () => config.get('server.uuid'),
        });
        const pool = new task_pool_1.TaskPool({
            logger,
            maxWorkers: this.maxWorkers,
        });
        const createRunner = (instance) => new task_runner_1.TaskManagerRunner({
            logger,
            kbnServer,
            instance,
            store,
            definitions: this.definitions,
            beforeRun: this.middleware.beforeRun,
        });
        const poller = new task_poller_1.TaskPoller({
            logger,
            pollInterval: config.get('xpack.task_manager.poll_interval'),
            store,
            work() {
                return fill_pool_1.fillPool(pool.run, store.fetchAvailableTasks, createRunner);
            },
        });
        this.logger = logger;
        this.store = store;
        this.poller = poller;
        kbnServer.afterPluginsInit(async () => {
            store.addSupportedTypes(Object.keys(this.definitions));
            const startPoller = () => {
                return poller
                    .start()
                    .then(() => {
                    this.isInitialized = true;
                })
                    .catch((err) => {
                    // FIXME: check the type of error to make sure it's actually an ES error
                    logger.warning(`PollError ${err.message}`);
                    // rety again to initialize store and poller, using the timing of
                    // task_manager's configurable poll interval
                    const retryInterval = config.get('xpack.task_manager.poll_interval');
                    setTimeout(() => startPoller(), retryInterval);
                });
            };
            return startPoller();
        });
    }
    /**
     * Method for allowing consumers to register task definitions into the system.
     * @param taskDefinitions - The Kibana task definitions dictionary
     */
    registerTaskDefinitions(taskDefinitions) {
        this.assertUninitialized('register task definitions');
        const duplicate = Object.keys(taskDefinitions).find(k => !!this.definitions[k]);
        if (duplicate) {
            throw new Error(`Task ${duplicate} is already defined!`);
        }
        try {
            const sanitized = sanitize_task_definitions_1.sanitizeTaskDefinitions(taskDefinitions, this.maxWorkers, this.overrideNumWorkers);
            Object.assign(this.definitions, sanitized);
        }
        catch (e) {
            this.logger.error('Could not sanitize task definitions');
        }
    }
    /**
     * Adds middleware to the task manager, such as adding security layers, loggers, etc.
     *
     * @param {Middleware} middleware - The middlware being added.
     */
    addMiddleware(middleware) {
        this.assertUninitialized('add middleware');
        const prevMiddleWare = this.middleware;
        this.middleware = middleware_1.addMiddlewareToChain(prevMiddleWare, middleware);
    }
    /**
     * Schedules a task.
     *
     * @param task - The task being scheduled.
     * @returns {Promise<ConcreteTaskInstance>}
     */
    async schedule(taskInstance, options) {
        this.assertInitialized('Tasks cannot be scheduled until after task manager is initialized!');
        const { taskInstance: modifiedTask } = await this.middleware.beforeSave({
            ...options,
            taskInstance,
        });
        const result = await this.store.schedule(modifiedTask);
        this.poller.attemptWork();
        return result;
    }
    /**
     * Fetches a paginatable list of scheduled tasks.
     *
     * @param opts - The query options used to filter tasks
     * @returns {Promise<FetchResult>}
     */
    async fetch(opts) {
        this.assertInitialized('Tasks cannot be fetched before task manager is initialized!');
        return this.store.fetch(opts);
    }
    /**
     * Removes the specified task from the index.
     *
     * @param {string} id
     * @returns {Promise<RemoveResult>}
     */
    async remove(id) {
        this.assertInitialized('Tasks cannot be removed before task manager is initialized!');
        return this.store.remove(id);
    }
    /**
     * Ensures task manager IS NOT already initialized
     *
     * @param {string} message shown if task manager is already initialized
     * @returns void
     */
    assertUninitialized(message) {
        if (this.isInitialized) {
            throw new Error(`Cannot ${message} after the task manager is initialized!`);
        }
    }
    /**
     * Ensures task manager IS already initialized
     *
     * @param {string} message shown if task manager is not initialized
     * @returns void
     */
    assertInitialized(message) {
        if (!this.isInitialized) {
            throw new Error(`NotInitialized: ${message}`);
        }
    }
}
exports.TaskManager = TaskManager;
