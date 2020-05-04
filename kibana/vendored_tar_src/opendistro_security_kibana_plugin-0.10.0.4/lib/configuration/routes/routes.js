import Boom from 'boom';
import Joi from 'joi';
import Resources from './../resources';

/**
 * If the error response contains an explicit reason
 * it should be used as the error's message
 * @param error
 * @returns {*}
 */
function enrichApiError(error) {
  const { body: { reason = '' } = {} } = error;
  if (error.output && reason) {
    error.output.payload.message = reason;
  }

  return error;
}

/**
 * The backend API allows to manage the backend configuration.
 *
 * NOTE: All routes are POST since the REST API requires an admin certificat to access
 *
 */
export default function (pluginRoot, server, APP_ROOT, API_ROOT) {

  const config = server.config();
  const backend = server.plugins.opendistro_security.getSecurityConfigurationBackend();


  /**
   * Returns a list of resource instances.
   *
   */
  server.route({
    method: 'GET',
    path: `${API_ROOT}/configuration/{resourceName}`,

      async handler (request, reply) {
        try {
          const results = await backend.list(request.headers, request.params.resourceName);
          return {
            total: Object.keys(results).length,
            data: results
          };
        } catch (error) {
          if (error.isBoom) {
            return enrichApiError(error);
          }
          throw enrichApiError(error);
        }
      },

    options: {
      validate: {
        params: {
          resourceName: Joi.string().required()
        }
      }
    }
  });

  /**
   * Returns a resource instance.
   *
   * Response sample:
   *
   * {
   *   "id": "kibiuser",
   * }
   */
  server.route({
    method: 'GET',
    path: `${API_ROOT}/configuration/{resourceName}/{id}`,

      async handler (request, h) {
        try {
          const result = await backend.get(request.headers, request.params.resourceName, request.params.id);
          return result;
        } catch (error) {
          if (error.name === 'NotFoundError') {
            return Boom.notFound(`${request.params.id} not found.`);
          } else {
            if (error.isBoom) {
              return enrichApiError(error);
            }
            throw enrichApiError(error);
          }
        }
      },

    options: {
      validate: {
        params: {
          resourceName: Joi.string().required(),
          id: Joi.string().required()
        }
      }
    }
  });


  /**
   * Deletes a resource instance.
   *
   * Response sample:
   *
   * {
   *   "message": "Deleted user username"
   * }
   */
  server.route({
    method: 'DELETE',
    path: `${API_ROOT}/configuration/{resourceName}/{id}`,

      async handler(request, h) {
        try {
          const response = await backend.delete(request.headers, request.params.resourceName, request.params.id);
          return {
            message: response.message
          };
        } catch (error) {
            if (error.isBoom) {
                return enrichApiError(error);
            }
            throw enrichApiError(error);
        }
      },

    options: {
      validate: {
        params: {
          resourceName: Joi.string().required(),
          id: Joi.string().required()
        }
      }
    }
  });


  /**
   * Updates or creates a resource
   *
   * Request sample:
   *
   * {
   *   "password": "password"
   * }
   */
  server.route({
    method: 'POST',
    path: `${API_ROOT}/configuration/{resourceName}/{id}`,
    async handler(request, h) {
        try {
          const response = await backend.save(request.headers, request.params.resourceName, request.params.id, request.payload);
          return {
              message: response.message
          }
        } catch (error) {
          if (error.isBoom) {
                return enrichApiError(error);
          }
          throw enrichApiError(error);
        }
    }
  });

  /**
   * Update a resource.
   * Resource identification is expected to computed from headers. Eg: auth headers
   *
   * Request sample:
   * /configuration/account
   * {
   *   "password": "new-password",
   *   "current_password": "old-password"
   * }
   */
  server.route({
    method: 'POST',
    path: `${API_ROOT}/configuration/{resourceName}`,
    async handler(request, h) {
        try {
          const response = await backend.saveWithoutId(request.headers, request.params.resourceName, request.payload);
          return {
              message: response.message
          }
        } catch (error) {
          if (error.isBoom) {
            return enrichApiError(error);
          }
          throw enrichApiError(error);
        }
    }
  });

  server.route({
    method: 'DELETE',
    path: `${API_ROOT}/configuration/cache`,
    async handler (request, h) {
        try {
          const response = await backend.clearCache(request.headers);
          return {
            message: response.message
          };
        } catch (error) {
            if (error.isBoom) {
                return enrichApiError(error);
            }
            throw enrichApiError(error);
        }
    }
  });


  server.route({
    method: 'GET',
    path: `${API_ROOT}/restapiinfo`,
    async handler (request, reply) {
        try {
          const response = await backend.restapiinfo(request.headers);
          return response;
        } catch (error) {
            if (error.isBoom) {
                return enrichApiError(error);
            }
            throw enrichApiError(error);
        }
    }
  });

  server.route({
    method: 'GET',
    path: `${API_ROOT}/configuration/indices`,
    async handler (request, h) {
        try {
          let response =  backend.indices(request.headers);
          return response;
        } catch (error) {
            if (error.isBoom) {
                return enrichApiError(error);
            }
            throw enrichApiError(error);
        }
      }
  });

    server.route({
        method: 'POST',
        path: `${API_ROOT}/configuration/validatedls/{indexName}`,
        async handler(request, reply) {
            try {
              const response = await backend.validateDls(request.headers, request.params.indexName, request.payload);
              return response;
            } catch (error) {
                if (error.isBoom) {
                    return enrichApiError(error);
                }
                throw enrichApiError(error);
            }
        }
    });

}

