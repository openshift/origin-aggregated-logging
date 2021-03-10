import { uniq } from 'lodash';

/**
 * Given a list of objects, returns an array containing the unique values in the attribute @textAttribute;
 * values that are falsy are removed from the result.
 *
 * @param {Array} list - A list of objects.
 * @param {String} textAttribute - The name of an object attribute that contains text.
 * @return {Array} an array of string values.
 */
export default function flatten(list, textAttribute) {
  return uniq(list.reduce((result, item) => {
    const text = item[textAttribute];
    if (text) {
      result.push(text);
    }
    return result;
  }, [])).sort();
};

