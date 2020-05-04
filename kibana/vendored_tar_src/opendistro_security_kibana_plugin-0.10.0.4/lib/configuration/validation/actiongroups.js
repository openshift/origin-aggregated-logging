import Joi from 'joi'

export default Joi.object().keys({
    permissions: Joi.array().items(Joi.string())
});
