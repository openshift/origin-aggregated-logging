"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const _1 = require("./");
const EventEmitter = require("eventemitter3"); // tslint:disable-line:import-name no-require-imports
const logger_1 = require("./logger");
const errors_1 = require("./errors");
const pkg = require('../package.json'); // tslint:disable-line:no-require-imports no-var-requires
/**
 * An object that monitors activity in an RTMClient and generates ping events in an effort to keep its websocket
 * connection alive. In cases where the websocket connection seems unresponsive, this object emits a
 * `recommend_reconnect` event. That event should be handled by tearing down the websocket connection and
 * opening a new one.
 */
class KeepAlive extends EventEmitter {
    constructor({ clientPingTimeout = 6000, serverPongTimeout = 4000, logger = undefined, logLevel = logger_1.LogLevel.INFO, } = {}) {
        super();
        this.clientPingTimeout = clientPingTimeout;
        this.serverPongTimeout = serverPongTimeout;
        if (this.serverPongTimeout >= this.clientPingTimeout) {
            throw errors_1.errorWithCode(new Error('client ping timeout must be less than server pong timeout'), _1.ErrorCode.KeepAliveConfigError);
        }
        this.isMonitoring = false;
        this.recommendReconnect = false;
        // Logging
        if (logger !== undefined) {
            this.logger = logger_1.loggerFromLoggingFunc(KeepAlive.loggerName, logger);
        }
        else {
            this.logger = logger_1.getLogger(KeepAlive.loggerName);
        }
        this.logger.setLevel(logLevel);
    }
    /**
     * Start monitoring the RTMClient. This method should only be called after the client's websocket is already open.
     */
    start(client) {
        this.logger.debug('start monitoring');
        if (!client.connected) {
            throw errors_1.errorWithCode(new Error(), _1.ErrorCode.KeepAliveClientNotConnected);
        }
        this.client = client;
        this.isMonitoring = true;
        this.client.on('outgoing_message', this.setPingTimer, this);
        this.setPingTimer();
    }
    /**
     * Stop monitoring the RTMClient. This method should be called after the `recommend_reconnect` event is emitted and
     * the client's weboscket is closed. In order to start monitoring the client again, start() needs to be called again
     * after that.
     */
    stop() {
        this.logger.debug('stop monitoring');
        this.clearPreviousPingTimer();
        this.clearPreviousPongTimer();
        if (this.client !== undefined) {
            this.client.off('outgoing_message', this.setPingTimer);
            this.client.off('slack_event', this.attemptAcknowledgePong);
        }
        this.lastPing = this.client = undefined;
        this.recommendReconnect = this.isMonitoring = false;
    }
    /**
     * Clears the ping timer if its set, otherwise this is a noop.
     */
    clearPreviousPingTimer() {
        if (this.pingTimer !== undefined) {
            clearTimeout(this.pingTimer);
            delete this.pingTimer;
        }
    }
    /**
     * Sets the ping timer (including clearing any previous one).
     */
    setPingTimer() {
        // if there's already an unacknowledged ping, we don't need to set up a timer for another to be sent
        if (this.lastPing !== undefined) {
            return;
        }
        this.logger.debug('setting ping timer');
        this.clearPreviousPingTimer();
        this.pingTimer = setTimeout(this.sendPing.bind(this), this.clientPingTimeout);
    }
    /**
     * Sends a ping and manages the timer to wait for a pong.
     */
    sendPing() {
        try {
            if (this.client === undefined) {
                if (!this.isMonitoring) {
                    // if monitoring stopped before the ping timer fires, its safe to return
                    this.logger.debug('stopped monitoring before ping timer fired');
                    return;
                }
                throw errors_1.errorWithCode(new Error('no client found'), _1.ErrorCode.KeepAliveInconsistentState);
            }
            this.logger.debug('ping timer expired, sending ping');
            this.client.send('ping')
                .then((messageId) => {
                if (this.client === undefined) {
                    if (!this.isMonitoring) {
                        // if monitoring stopped before the ping is sent, its safe to return
                        this.logger.debug('stopped monitoring before outgoing ping message was finished');
                        return;
                    }
                    throw errors_1.errorWithCode(new Error('no client found'), _1.ErrorCode.KeepAliveInconsistentState);
                }
                this.lastPing = messageId;
                this.logger.debug('setting pong timer');
                this.pongTimer = setTimeout(() => {
                    if (this.client === undefined) {
                        // if monitoring stopped before the pong timer fires, its safe to return
                        if (!this.isMonitoring) {
                            this.logger.debug('stopped monitoring before pong timer fired');
                            return;
                        }
                        throw errors_1.errorWithCode(new Error('no client found'), _1.ErrorCode.KeepAliveInconsistentState);
                    }
                    // signal that this pong is done being handled
                    this.client.off('slack_event', this.attemptAcknowledgePong);
                    // no pong received to acknowledge the last ping within the serverPongTimeout
                    this.logger.debug('pong timer expired, recommend reconnect');
                    this.recommendReconnect = true;
                    this.emit('recommend_reconnect');
                }, this.serverPongTimeout);
                this.client.on('slack_event', this.attemptAcknowledgePong, this);
            })
                .catch((error) => {
                this.logger.error(`Unhandled error: ${error.message}. Please report to @slack/client package maintainers.`);
            });
        }
        catch (error) {
            this.logger.error(`Unhandled error: ${error.message}. Please report to @slack/client package maintainers.`);
        }
    }
    /**
     * Clears the pong timer if its set, otherwise this is a noop.
     */
    clearPreviousPongTimer() {
        if (this.pongTimer !== undefined) {
            clearTimeout(this.pongTimer);
        }
    }
    /**
     * Determines if a giving incoming event can be treated as an acknowledgement for the outstanding ping, and then
     * clears the ping if so.
     * @param event any incoming slack event
     */
    attemptAcknowledgePong(_type, event) {
        if (this.client === undefined) {
            throw errors_1.errorWithCode(new Error('no client found'), _1.ErrorCode.KeepAliveInconsistentState);
        }
        if (this.lastPing !== undefined && event.reply_to !== undefined && event.reply_to >= this.lastPing) {
            // this message is a reply that acks the previous ping, clear the last ping
            this.logger.debug('received pong, clearing pong timer');
            delete this.lastPing;
            // signal that this pong is done being handled
            this.clearPreviousPongTimer();
            this.client.off('slack_event', this.attemptAcknowledgePong);
        }
    }
}
/**
 * The name used to prefix all logging generated from this object
 */
KeepAlive.loggerName = `${pkg.name}:KeepAlive`;
exports.KeepAlive = KeepAlive;
//# sourceMappingURL=KeepAlive.js.map