export default function (kibana) {
  return new kibana.Plugin({
    uiExports: {
      visTypes: [
        'plugins/origin-kibana/styles/main.css',
        'plugins/origin-kibana/styles/overrides.css',
        'plugins/origin-kibana/directives',
        'plugins/origin-kibana/headerController',
        'plugins/origin-kibana/userstore',
        'plugins/origin-kibana/logger'
      ],
    },

    config(Joi) {
      return Joi.object({
        enabled: Joi.boolean().default(true),
      }).default();
    }
  });
};
