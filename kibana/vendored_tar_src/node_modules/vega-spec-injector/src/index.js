export default class {
  constructor(onWarning) {
    this.onWarning = onWarning || (console ? console.log : () => {
    });
  }

  /**
   * Add values like signals to a vega spec, or ignore if the they are already defined.
   * @param {object} spec vega spec to modify and return
   * @param {string} field name of the vega spec branch, e.g. `signals`
   * @param {<object|string>[]} values to add
   * @return {object} returns the same spec object as passed in
   */
  addToList(spec, field, values) {
    const newSigs = new Map(values.map(v => typeof v === `string` ? [v, {name: v}] : [v.name, v]));

    for (const sig of this.findUndefined(spec, field, newSigs.keys())) {
      spec[field].push(newSigs.get(sig));
    }

    return spec;
  }

  /**
   * Set a spec field, and warn if overriding an existing value in that field
   * @param {object} spec vega spec to modify and return
   * @param {string} field
   * @param {*} value
   * @return {object} returns the same spec object as passed in
   */
  overrideField(spec, field, value) {
    if (spec[field] && spec[field] !== value) {
      this.onWarning(`Overriding ${field}: ${spec[field]} 𐃘 ${value}`);
    }
    spec[field] = value;
    return spec;
  }

  /**
   * Find all names that are not defined in the spec's section. Creates section if missing.
   * @param {object} spec
   * @param {string} section
   * @param {Iterable.<string>} names
   * @return {Iterable.<string>}
   */
  findUndefined(spec, section, names) {
    if (!spec.hasOwnProperty(section)) {
      spec[section] = [];
      return names;
    } else if (!Array.isArray(spec[section])) {
      throw new Error(`spec.${section} must be an array`);
    }

    const nameStrings = new Set(names);
    for (const obj of spec[section]) {
      // If obj has a name field, delete that name from the names
      // Set will silently ignore delete() for undefined names
      if (obj.name) nameStrings.delete(obj.name);
    }

    return nameStrings;
  }
}
