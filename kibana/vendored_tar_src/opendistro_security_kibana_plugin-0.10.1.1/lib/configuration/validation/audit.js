import Joi from 'joi';

export default Joi.object().keys({
  enabled: Joi.boolean(),
  audit: Joi.object().keys({
    enable_rest: Joi.boolean(),
    disabled_rest_categories: Joi.array().items(
      'AUTHENTICATED',
      'BAD_HEADERS',
      'FAILED_LOGIN',
      'GRANTED_PRIVILEGES',
      'MISSING_PRIVILEGES',
      'SSL_EXCEPTION'
    ),
    enable_transport: Joi.boolean(),
    disabled_transport_categories: Joi.array().items(
      'AUTHENTICATED',
      'BAD_HEADERS',
      'FAILED_LOGIN',
      'GRANTED_PRIVILEGES',
      'INDEX_EVENT',
      'MISSING_PRIVILEGES',
      'OPENDISTRO_SECURITY_INDEX_ATTEMPT',
      'SSL_EXCEPTION'
    ),
    resolve_bulk_requests: Joi.boolean(),
    log_request_body: Joi.boolean(),
    resolve_indices: Joi.boolean(),
    exclude_sensitive_headers: Joi.boolean(),
    ignore_users: Joi.array().items(Joi.string()),
    ignore_requests: Joi.array().items(Joi.string()),
  }),
  compliance: Joi.object({
    enabled: Joi.boolean(),
    external_config: Joi.boolean(),
    internal_config: Joi.boolean(),
    read_metadata_only: Joi.boolean(),
    read_ignore_users: Joi.array().items(Joi.string()),
    read_watched_fields: Joi.object(),
    write_log_diffs: Joi.boolean(),
    write_metadata_only: Joi.boolean(),
    write_ignore_users: Joi.array().items(Joi.string()),
    write_watched_indices: Joi.array().items(Joi.string()),
  }),
});
