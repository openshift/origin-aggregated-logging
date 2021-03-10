/**
 * Thrown when an existing object with the same identifier already exists.
 */
export default class ConflictError {
  /**
   * Creates a new ConflictError.
   *
   * @param {string} message - The error message.
   * @param {Error} inner - An optional error that caused the ConflictError.
   */
  constructor(message, inner) {
    this.name = 'ConflictError';
    this.message = message;
    this.inner = inner;
    this.stack = new Error().stack;
  }
}
