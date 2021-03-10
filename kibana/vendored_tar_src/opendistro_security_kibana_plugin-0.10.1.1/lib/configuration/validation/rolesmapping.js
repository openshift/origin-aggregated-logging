import Joi from 'joi'

export default Joi.object().keys({
    backendroles: Joi.array().items(Joi.string()),
    hosts: Joi.array().items(Joi.string()),
    users: Joi.array().items(Joi.string())
});
