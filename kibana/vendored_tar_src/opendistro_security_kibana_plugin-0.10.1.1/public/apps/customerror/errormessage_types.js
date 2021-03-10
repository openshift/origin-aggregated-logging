export const messageTypes = {
    /**
     * In case no message type is provided
     */
    'default': {
        title: 'Logged out',
        subtitle: 'Please login with a new token.',
    },

    /**
     * User does not have any valid tenant
     */
    missingTenant: {
        title: 'Missing Tenant',
        subtitle: 'No tenant available for this user, please contact your system administrator.',
    },

    /**
     * User does not have any valid role
     */
    missingRole: {
        title: 'Missing Role',
        subtitle: 'No roles available for this user, please contact your system administrator.',
    },

    /**
     * Session expired, most likely shown after an AJAX call from within Kibana
     */
    sessionExpired: {
        title: 'Session Expired',
        subtitle: 'Please provide a new token.',
    },

    /**
     * General authentication error
     */
    authError: {
        title: 'Authentication failed',
        subtitle: 'Please provide a new token.',
    },

    samlConfigError: {
      title: 'SAML configuration error',
      subtitle: 'Something went wrong while retrieving the SAML configuration, please check your settings.',
    },

    samlAuthError: {
        title: 'SAML authentication error',
        subtitle: 'The SAML authentication failed. Please contact your administrator.'
    },

    samlLogoutSuccess: {
        title: 'You have been logged out.',
        subtitle: ''
    },

    anonymousAuthError: {
        title: 'Anonymous authentication error',
        subtitle: 'Please make sure that anonymous auth is enabled in Security.'
    },

    proxycacheAuthError: {
        title: 'Authentication failed',
        subtitle: 'Please login again',
    },

    proxycacheLogout: {
        title: 'You have been logged out.',
        subtitle: ''
    },
};
