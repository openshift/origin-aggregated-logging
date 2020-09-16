import { resolve } from 'path';

export default function (kibana) {
  return new kibana.Plugin({
    name: 'openshift_logging',
    id: 'openshift_logging',
    require: ['elasticsearch'],

    uiExports: {
      
      hacks: [
        //the path here is misleading as it matches the 'name' not actual path
        'plugins/openshift_logging/interceptors'
      ]
      
    },

    config(Joi) {
      return Joi.object({
        enabled: Joi.boolean().default(true),
      }).default();
    },

    init(server, options) {
    }

  });
};
