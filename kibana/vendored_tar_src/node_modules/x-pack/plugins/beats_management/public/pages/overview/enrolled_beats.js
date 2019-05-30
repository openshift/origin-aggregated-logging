"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const eui_1 = require("@elastic/eui");
const i18n_1 = require("@kbn/i18n");
const react_1 = require("@kbn/i18n/react");
const lodash_1 = require("lodash");
const moment_1 = tslib_1.__importDefault(require("moment"));
const react_2 = tslib_1.__importDefault(require("react"));
const enroll_beats_1 = require("../../components/enroll_beats");
const breadcrumb_1 = require("../../components/navigation/breadcrumb");
const table_1 = require("../../components/table");
const action_schema_1 = require("../../components/table/action_schema");
const table_2 = require("../../components/table/table");
const with_kuery_autocompletion_1 = require("../../containers/with_kuery_autocompletion");
class BeatsPageComponent extends react_2.default.PureComponent {
    constructor(props) {
        super(props);
        this.tableRef = react_2.default.createRef();
        this.renderActionArea = () => (react_2.default.createElement(react_2.default.Fragment, null,
            react_2.default.createElement(eui_1.EuiButtonEmpty, { onClick: () => {
                    // random, but specific number ensures new tab does not overwrite another _newtab in chrome
                    // and at the same time not truly random so that many clicks of the link open many tabs at this same URL
                    window.open('https://www.elastic.co/guide/en/beats/libbeat/current/getting-started.html', '_newtab35628937456');
                } },
                react_2.default.createElement(react_1.FormattedMessage, { id: "xpack.beatsManagement.beats.installBeatsLearningButtonLabel", defaultMessage: "Learn how to install beats" })),
            react_2.default.createElement(eui_1.EuiButton, { size: "s", color: "primary", onClick: async () => {
                    this.props.goTo(`/overview/enrolled_beats/enroll`);
                } },
                react_2.default.createElement(react_1.FormattedMessage, { id: "xpack.beatsManagement.beats.enrollBeatsButtonLabel", defaultMessage: "Enroll Beats" })),
            this.props.location.pathname === '/overview/enrolled_beats/enroll' && (react_2.default.createElement(eui_1.EuiOverlayMask, null,
                react_2.default.createElement(eui_1.EuiModal, { onClose: () => {
                        this.props.setUrlState({
                            enrollmentToken: '',
                        });
                        this.props.goTo(`/overview/enrolled_beats`);
                    }, style: { width: '640px' } },
                    react_2.default.createElement(eui_1.EuiModalHeader, null,
                        react_2.default.createElement(eui_1.EuiModalHeaderTitle, null,
                            react_2.default.createElement(react_1.FormattedMessage, { id: "xpack.beatsManagement.beats.enrollNewBeatsTitle", defaultMessage: "Enroll a new Beat" }))),
                    react_2.default.createElement(eui_1.EuiModalBody, null,
                        react_2.default.createElement(enroll_beats_1.EnrollBeat, { frameworkBasePath: this.props.libs.framework.info.basePath, enrollmentToken: this.props.urlState.enrollmentToken, getBeatWithToken: this.props.containers.beats.getBeatWithToken, createEnrollmentToken: async () => {
                                const enrollmentTokens = await this.props.libs.tokens.createEnrollmentTokens();
                                this.props.setUrlState({
                                    enrollmentToken: enrollmentTokens[0],
                                });
                            }, onBeatEnrolled: () => {
                                this.props.setUrlState({
                                    enrollmentToken: '',
                                });
                            } }),
                        !this.props.urlState.enrollmentToken && (react_2.default.createElement(react_2.default.Fragment, null,
                            react_2.default.createElement(eui_1.EuiButton, { size: "s", color: "primary", style: { marginLeft: 10 }, onClick: async () => {
                                    this.props.goTo('/overview/enrolled_beats');
                                } }, "Done")))))))));
        this.notifyBeatDisenrolled = async (beats) => {
            const { intl } = this.props;
            let title;
            let text;
            if (beats.length === 1) {
                title = intl.formatMessage({
                    id: 'xpack.beatsManagement.beats.beatDisenrolledNotificationTitle',
                    defaultMessage: '{firstBeatNameOrId} disenrolled',
                }, {
                    firstBeatNameOrId: `"${beats[0].name || beats[0].id}"`,
                });
                text = intl.formatMessage({
                    id: 'xpack.beatsManagement.beats.beatDisenrolledNotificationDescription',
                    defaultMessage: 'Beat with ID {firstBeatId} was disenrolled.',
                }, {
                    firstBeatId: `"${beats[0].id}"`,
                });
            }
            else {
                title = intl.formatMessage({
                    id: 'xpack.beatsManagement.beats.disenrolledBeatsNotificationTitle',
                    defaultMessage: '{beatsLength} beats disenrolled',
                }, {
                    beatsLength: beats.length,
                });
            }
            this.setState({
                notifications: this.state.notifications.concat({
                    color: 'warning',
                    id: `disenroll_${new Date()}`,
                    title,
                    text,
                }),
            });
        };
        this.notifyUpdatedTagAssociation = (action, beats, tag) => {
            const { intl } = this.props;
            const notificationMessage = action === 'removed'
                ? intl.formatMessage({
                    id: 'xpack.beatsManagement.beats.removedNotificationDescription',
                    defaultMessage: 'Removed tag {tag} from {assignmentsLength, plural, one {beat {beatName}} other {# beats}}.',
                }, {
                    tag: `"${tag}"`,
                    assignmentsLength: beats.length,
                    beatName: `"${beats[0].name || beats[0].id}"`,
                })
                : intl.formatMessage({
                    id: 'xpack.beatsManagement.beats.addedNotificationDescription',
                    defaultMessage: 'Added tag {tag} to {assignmentsLength, plural, one {beat {beatName}} other {# beats}}.',
                }, {
                    tag: `"${tag}"`,
                    assignmentsLength: beats.length,
                    beatName: `"${beats[0].name || beats[0].id}"`,
                });
            const notificationTitle = action === 'removed'
                ? intl.formatMessage({
                    id: 'xpack.beatsManagement.beats.removedNotificationTitle',
                    defaultMessage: '{assignmentsLength, plural, one {Tag} other {Tags}} removed',
                }, {
                    assignmentsLength: beats.length,
                })
                : intl.formatMessage({
                    id: 'xpack.beatsManagement.beats.addedNotificationTitle',
                    defaultMessage: '{assignmentsLength, plural, one {Tag} other {Tags}} added',
                }, {
                    assignmentsLength: beats.length,
                });
            this.setState({
                notifications: this.state.notifications.concat({
                    color: 'success',
                    id: `tag-${moment_1.default.now()}`,
                    text: react_2.default.createElement("p", null, notificationMessage),
                    title: notificationTitle,
                }),
            });
        };
        this.getSelectedBeats = () => {
            if (!this.tableRef.current) {
                return [];
            }
            const selectedIds = this.tableRef.current.state.selection.map((beat) => beat.id);
            const beats = [];
            selectedIds.forEach((id) => {
                const beat = this.props.containers.beats.state.list.find(b => b.id === id);
                if (beat) {
                    beats.push(beat);
                }
            });
            return beats;
        };
        this.state = {
            notifications: [],
            tags: null,
            beats: [],
            assignmentOptions: null,
        };
        props.renderAction(this.renderActionArea);
    }
    componentDidMount() {
        if (this.props.urlState.beatsKBar) {
            this.props.containers.beats.reload(this.props.urlState.beatsKBar);
        }
        this.updateBeatsData(this.props.urlState.beatsKBar);
    }
    async updateBeatsData(beatsKBar) {
        const beats = lodash_1.sortBy(await this.props.libs.beats.getAll(beatsKBar), 'id') || [];
        const tags = await this.props.libs.tags.getTagsWithIds(lodash_1.flatten(beats.map(beat => beat.tags)));
        this.setState({
            tags,
            beats,
        });
    }
    render() {
        return (react_2.default.createElement(react_2.default.Fragment, null,
            react_2.default.createElement(breadcrumb_1.Breadcrumb, { title: i18n_1.i18n.translate('xpack.beatsManagement.breadcrumb.enrolledBeats', {
                    defaultMessage: 'Enrolled Beats',
                }), path: `/overview/enrolled_beats` }),
            react_2.default.createElement(with_kuery_autocompletion_1.WithKueryAutocompletion, { libs: this.props.libs, fieldPrefix: "beat" }, autocompleteProps => (react_2.default.createElement(table_1.Table, { kueryBarProps: {
                    ...autocompleteProps,
                    filterQueryDraft: 'false',
                    isValid: this.props.libs.elasticsearch.isKueryValid(this.props.urlState.beatsKBar || ''),
                    onChange: (value) => {
                        this.props.setUrlState({ beatsKBar: value });
                        this.updateBeatsData(value);
                    },
                    onSubmit: () => null,
                    value: this.props.urlState.beatsKBar || '',
                }, actions: action_schema_1.beatsListActions, actionData: {
                    tags: this.state.assignmentOptions,
                }, actionHandler: async (action, payload) => {
                    switch (action) {
                        case table_2.AssignmentActionType.Assign:
                            const status = await this.props.containers.beats.toggleTagAssignment(payload, this.getSelectedBeats());
                            await this.updateBeatsData();
                            this.notifyUpdatedTagAssociation(status, this.getSelectedBeats(), payload);
                            break;
                        case table_2.AssignmentActionType.Delete:
                            await this.props.containers.beats.deactivate(this.getSelectedBeats());
                            await this.updateBeatsData();
                            this.notifyBeatDisenrolled(this.getSelectedBeats());
                            break;
                        case table_2.AssignmentActionType.Reload:
                            const assignmentOptions = await this.props.libs.tags.getassignableTagsForBeats(this.getSelectedBeats());
                            this.setState({ assignmentOptions });
                            break;
                    }
                }, items: this.state.beats.map(beat => ({
                    ...beat,
                    tags: (this.state.tags || []).filter(tag => beat.tags.includes(tag.id)),
                })), ref: this.tableRef, type: table_1.BeatsTableType }))),
            react_2.default.createElement(eui_1.EuiGlobalToastList, { toasts: this.state.notifications, dismissToast: () => this.setState({ notifications: [] }), toastLifeTimeMs: 5000 })));
    }
}
exports.BeatsPage = react_1.injectI18n(BeatsPageComponent);
