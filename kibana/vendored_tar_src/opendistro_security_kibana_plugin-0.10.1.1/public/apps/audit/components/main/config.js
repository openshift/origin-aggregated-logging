import React, { Fragment } from 'react';

export const AUDIT_API = {
  PUT: '../api/v1/configuration/audit/config',
  GET: '../api/v1/configuration/audit',
};

export const CONFIG_LABELS = {
  AUDIT_LOGGING: 'Audit logging',
  GENERAL_SETTINGS: 'General settings',
  LAYER_SETTINGS: 'Layer settings',
  ATTRIBUTE_SETTINGS: 'Attribute settings',
  IGNORE_SETTINGS: 'Ignore settings',
  COMPLIANCE_SETTINGS: 'Compliance settings',
  COMPLIANCE_CONFIG_SETTINGS: 'Config',
  COMPLIANCE_READ: 'Read',
  COMPLIANCE_WRITE: 'Write',
};

export const TOAST_MESSAGES = {
  GENERAL_SETTINGS: 'General settings saved',
  COMPLIANCE_SETTINGS: 'Compliance settings saved',
};

export const RESPONSE_MESSAGES = {
  FETCH_ERROR_TITLE: 'Sorry, there was an error fetching audit configuration.',
  FETCH_ERROR_MESSAGE:
    'Please ensure hot reloading of audit configuration is enabled in the security plugin.',
  UPDATE_SUCCESS: 'Audit configuration was successfully updated.',
  UPDATE_FAILURE: 'Audit configuration could not be updated. Please check configuration.',
};

const CONFIG = {
  ENABLED: {
    title: 'Enable audit logging',
    path: 'enabled',
    type: 'bool',
    hideLabel: true,
  },
  STORAGE: {
    title: 'Storage location',
    path: '',
    content: <Fragment>Configure the output location and storage types in <code>elasticsearch.yml</code> . The default storage location is <code>internal_elasticsearch</code>, which stores the logs in an index on this cluster. </Fragment>,
    url: 'https://opendistro.github.io/for-elasticsearch-docs/docs/security/audit-logs/',
    type: 'text',
  },
  AUDIT: {
    REST_LAYER: {
      title: 'REST layer',
      path: 'audit.enable_rest',
      description: 'Enable or disable auditing events that happen on the REST layer.',
      type: 'bool',
    },
    REST_DISABLED_CATEGORIES: {
      title: 'REST disabled categories',
      path: 'audit.disabled_rest_categories',
      description: 'Specify audit categories which must be ignored on the REST layer. Modifying these could result in significant overhead.',
      type: 'array',
      options: [
        'AUTHENTICATED',
        'BAD_HEADERS',
        'FAILED_LOGIN',
        'GRANTED_PRIVILEGES',
        'MISSING_PRIVILEGES',
        'SSL_EXCEPTION'
      ],
    },
    TRANSPORT_LAYER: {
      title: 'Transport layer',
      path: 'audit.enable_transport',
      description: 'Enable or disable auditing events that happen on the transport layer.',
      type: 'bool',
    },
    TRANSPORT_DISABLED_CATEGORIES: {
      title: 'Transport disabled categories',
      path: 'audit.disabled_transport_categories',
      description: 'Specify audit categories which must be ignored on the transport layer. Modifying these could result in significant overhead.',
      type: 'array',
      options: [
        'AUTHENTICATED',
        'BAD_HEADERS',
        'FAILED_LOGIN',
        'GRANTED_PRIVILEGES',
        'INDEX_EVENT',
        'MISSING_PRIVILEGES',
        'OPENDISTRO_SECURITY_INDEX_ATTEMPT',
        'SSL_EXCEPTION',
      ],
    },
    BULK_REQUESTS: {
      title: 'Bulk requests',
      path: 'audit.resolve_bulk_requests',
      description: 'Resolve bulk requests during auditing of requests. Enabling this will generate a log for each document request which could result in significant overhead.',
      type: 'bool',
    },
    REQUEST_BODY: {
      title: 'Request body',
      path: 'audit.log_request_body',
      description: 'Include request body during auditing of requests.',
      type: 'bool',
    },
    RESOLVE_INDICES: {
      title: 'Resolve indices',
      path: 'audit.resolve_indices',
      description: 'Resolve indices during auditing of requests.',
      type: 'bool',
    },
    SENSITIVE_HEADERS: {
      title: 'Sensitive headers',
      path: 'audit.exclude_sensitive_headers',
      description: 'Exclude sensitive headers during auditing. Eg: Authorization header.',
      type: 'bool',
    },
    IGNORED_USERS: {
      title: 'Ignored users',
      path: 'audit.ignore_users',
      description: 'Users to ignore during auditing.',
      type: 'array',
      helpText: 'User or user pattern.',
    },
    IGNORED_REQUESTS: {
      title: 'Ignored requests',
      path: 'audit.ignore_requests',
      description: 'Request patterns to ignore during auditing.',
      type: 'array',
      helpText: 'Request or request pattern.',
    },
  },
  COMPLIANCE: {
    ENABLED: {
      title: 'Compliance logging',
      path: 'compliance.enabled',
      description: 'Enable or disable compliance logging.',
      type: 'bool',
      hideLabel: true,
    },
    INTERNAL_CONFIG: {
      title: 'Internal config logging',
      path: 'compliance.internal_config',
      description: 'Enable or disable logging of events on internal security index.',
      type: 'bool',
    },
    EXTERNAL_CONFIG: {
      title: 'External config logging',
      path: 'compliance.external_config',
      description: 'Enable or disable logging of external configuration.',
      type: 'bool',
    },
    READ_METADATA_ONLY: {
      title: 'Read metadata',
      path: 'compliance.read_metadata_only',
      description: 'Log only metadata of the document. Do not log any document fields.',
      type: 'bool',
    },
    READ_IGNORED_USERS: {
      title: 'Ignored users',
      path: 'compliance.read_ignore_users',
      description: 'Users to ignore during auditing.',
      type: 'array',
      helpText: 'User or user pattern.',
    },
    READ_WATCHED_FIELDS: {
      title: 'Watched fields',
      path: 'compliance.read_watched_fields',
      description:
        'List the indices and fields to watch during read events. Adding watched fields will generate one log per document access and could result in significant overhead. Sample data content:',
      type: 'map',
      code: `{
  "index-name-pattern": ["field-name-pattern"],
  "logs*": ["message"],
  "twitter": ["id", "user*"]
}`,
      error: 'Invalid content. Please check sample data content.',
    },
    WRITE_METADATA_ONLY: {
      title: 'Write metadata',
      path: 'compliance.write_metadata_only',
      description: 'Log only metadata of the document. Do not log any document content.',
      type: 'bool',
    },
    WRITE_LOG_DIFFS: {
      title: 'Log diffs',
      path: 'compliance.write_log_diffs',
      description: 'Log only diffs for document updates.',
      type: 'bool',
    },
    WRITE_IGNORED_USERS: {
      title: 'Ignored users',
      path: 'compliance.write_ignore_users',
      description: 'Users to ignore during auditing.',
      type: 'array',
      helpText: 'User or user pattern.',
    },
    WRITE_WATCHED_FIELDS: {
      title: 'Watch indices',
      path: 'compliance.write_watched_indices',
      description: 'List the indices to watch during write events. Adding watched indices will generate one log per document access and could result in significant overhead.',
      type: 'array',
      helpText: 'Index name or index pattern.',
    },
  },
};

export const SETTING_GROUPS = {
  AUDIT_SETTINGS: {
    settings: [CONFIG.STORAGE, CONFIG.ENABLED],
  },
  LAYER_SETTINGS: {
    title: CONFIG_LABELS.LAYER_SETTINGS,
    settings: [
      CONFIG.AUDIT.REST_LAYER,
      CONFIG.AUDIT.REST_DISABLED_CATEGORIES,
      CONFIG.AUDIT.TRANSPORT_LAYER,
      CONFIG.AUDIT.TRANSPORT_DISABLED_CATEGORIES,
    ],
  },
  ATTRIBUTE_SETTINGS: {
    title: CONFIG_LABELS.ATTRIBUTE_SETTINGS,
    settings: [
      CONFIG.AUDIT.BULK_REQUESTS,
      CONFIG.AUDIT.REQUEST_BODY,
      CONFIG.AUDIT.RESOLVE_INDICES,
      CONFIG.AUDIT.SENSITIVE_HEADERS,
    ],
  },
  IGNORE_SETTINGS: {
    title: CONFIG_LABELS.IGNORE_SETTINGS,
    settings: [CONFIG.AUDIT.IGNORED_USERS, CONFIG.AUDIT.IGNORED_REQUESTS],
  },
  COMPLIANCE_LOGGING_SETTINGS: {
    settings: [CONFIG.COMPLIANCE.ENABLED],
  },
  COMPLIANCE_CONFIG_SETTINGS: {
    title: CONFIG_LABELS.COMPLIANCE_CONFIG_SETTINGS,
    settings: [CONFIG.COMPLIANCE.INTERNAL_CONFIG, CONFIG.COMPLIANCE.EXTERNAL_CONFIG],
  },
  COMPLIANCE_READ_SETTINGS: {
    title: CONFIG_LABELS.COMPLIANCE_READ,
    settings: [
      CONFIG.COMPLIANCE.READ_METADATA_ONLY,
      CONFIG.COMPLIANCE.READ_IGNORED_USERS,
      CONFIG.COMPLIANCE.READ_WATCHED_FIELDS,
    ],
  },
  COMPLIANCE_WRITE_SETTINGS: {
    title: CONFIG_LABELS.COMPLIANCE_WRITE,
    settings: [
      CONFIG.COMPLIANCE.WRITE_METADATA_ONLY,
      CONFIG.COMPLIANCE.WRITE_LOG_DIFFS,
      CONFIG.COMPLIANCE.WRITE_IGNORED_USERS,
      CONFIG.COMPLIANCE.WRITE_WATCHED_FIELDS,
    ],
  },
};
