import Joi from 'joi'

export default Joi.object().keys({
    password: Joi.string().allow(''),
    roles: Joi.array().items(Joi.string()),
    attributes: Joi.object()
});
