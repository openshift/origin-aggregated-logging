"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const NANMATRIX = [
    NaN,
    NaN,
    NaN,
    NaN,
    NaN,
    NaN,
    NaN,
    NaN,
    NaN,
    NaN,
    NaN,
    NaN,
    NaN,
    NaN,
    NaN,
    NaN,
];
exports.ORIGIN = [0, 0, 0, 1];
exports.translate = (x, y, z) => [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, x, y, z, 1];
exports.scale = (x, y, z) => [x, 0, 0, 0, 0, y, 0, 0, 0, 0, z, 0, 0, 0, 0, 1];
exports.rotateZ = (a) => {
    const sinA = Math.sin(a);
    const cosA = Math.cos(a);
    return [cosA, -sinA, 0, 0, sinA, cosA, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1];
};
/**
 * multiply
 *
 * Matrix multiplies two matrices of column major format, returning the result in the same format
 *
 *
 *                               A    E    I    M
 *                               B    F    J    N
 *                               C    G    K    O
 *                               D    H    L    P
 *
 *         a    e    i    m      .    .    .    .
 *         b    f    j    n      .    .    .    .
 *         c    g    k    o      .    .    .    .
 *         d    h    l    p      .    .    .    d * M + h * N + l * O + p * P
 *
 */
const mult = ([a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p], [A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P]) => [
    a * A + e * B + i * C + m * D,
    b * A + f * B + j * C + n * D,
    c * A + g * B + k * C + o * D,
    d * A + h * B + l * C + p * D,
    a * E + e * F + i * G + m * H,
    b * E + f * F + j * G + n * H,
    c * E + g * F + k * G + o * H,
    d * E + h * F + l * G + p * H,
    a * I + e * J + i * K + m * L,
    b * I + f * J + j * K + n * L,
    c * I + g * J + k * K + o * L,
    d * I + h * J + l * K + p * L,
    a * M + e * N + i * O + m * P,
    b * M + f * N + j * O + n * P,
    c * M + g * N + k * O + o * P,
    d * M + h * N + l * O + p * P,
];
exports.multiply = (first, ...rest) => rest.reduce((prev, next) => mult(prev, next), first);
/**
 * mvMultiply
 *
 * Multiplies a matrix and a vector
 *
 *
 *                               A
 *                               B
 *                               C
 *                               D
 *
 *         a    e    i    m      .
 *         b    f    j    n      .
 *         c    g    k    o      .
 *         d    h    l    p      d * A + h * B + l * C + p * D
 *
 */
exports.mvMultiply = ([a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p], [A, B, C, D]) => [
    a * A + e * B + i * C + m * D,
    b * A + f * B + j * C + n * D,
    c * A + g * B + k * C + o * D,
    d * A + h * B + l * C + p * D,
];
exports.normalize = ([A, B, C, D]) => D === 1 ? [A, B, C, D] : [A / D, B / D, C / D, 1];
/**
 * invert
 *
 * Inverts the matrix
 *
 *         a    e    i    m
 *         b    f    j    n
 *         c    g    k    o
 *         d    h    l    p
 */
exports.invert = ([a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p,]) => {
    const inv = [
        f * k * p - f * l * o - j * g * p + j * h * o + n * g * l - n * h * k,
        -b * k * p + b * l * o + j * c * p - j * d * o - n * c * l + n * d * k,
        b * g * p - b * h * o - f * c * p + f * d * o + n * c * h - n * d * g,
        -b * g * l + b * h * k + f * c * l - f * d * k - j * c * h + j * d * g,
        -e * k * p + e * l * o + i * g * p - i * h * o - m * g * l + m * h * k,
        a * k * p - a * l * o - i * c * p + i * d * o + m * c * l - m * d * k,
        -a * g * p + a * h * o + e * c * p - e * d * o - m * c * h + m * d * g,
        a * g * l - a * h * k - e * c * l + e * d * k + i * c * h - i * d * g,
        e * j * p - e * l * n - i * f * p + i * h * n + m * f * l - m * h * j,
        -a * j * p + a * l * n + i * b * p - i * d * n - m * b * l + m * d * j,
        a * f * p - a * h * n - e * b * p + e * d * n + m * b * h - m * d * f,
        -a * f * l + a * h * j + e * b * l - e * d * j - i * b * h + i * d * f,
        -e * j * o + e * k * n + i * f * o - i * g * n - m * f * k + m * g * j,
        a * j * o - a * k * n - i * b * o + i * c * n + m * b * k - m * c * j,
        -a * f * o + a * g * n + e * b * o - e * c * n - m * b * g + m * c * f,
        a * f * k - a * g * j - e * b * k + e * c * j + i * b * g - i * c * f,
    ];
    const det = a * inv[0] + b * inv[4] + c * inv[8] + d * inv[12];
    if (det === 0) {
        return NANMATRIX; // no real solution
    }
    else {
        const recDet = 1 / det;
        for (let index = 0; index < 16; index++) {
            inv[index] *= recDet;
        }
        return inv;
    }
};
exports.translateComponent = (a) => [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, a[12], a[13], a[14], 1];
exports.compositeComponent = ([a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p,]) => [a, b, c, d, e, f, g, h, i, j, k, l, 0, 0, 0, p];
exports.add = ([a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p], [A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P]) => [
    a + A,
    b + B,
    c + C,
    d + D,
    e + E,
    f + F,
    g + G,
    h + H,
    i + I,
    j + J,
    k + K,
    l + L,
    m + M,
    n + N,
    o + O,
    p + P,
];
exports.subtract = ([a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p], [A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P]) => [
    a - A,
    b - B,
    c - C,
    d - D,
    e - E,
    f - F,
    g - G,
    h - H,
    i - I,
    j - J,
    k - K,
    l - L,
    m - M,
    n - N,
    o - O,
    p - P,
];
exports.reduceTransforms = (transforms) => transforms.length === 1
    ? transforms[0]
    : transforms.slice(1).reduce((prev, next) => exports.multiply(prev, next), transforms[0]);
const clamp = (low, high, value) => Math.min(high, Math.max(low, value));
exports.matrixToAngle = (transformMatrix) => {
    // clamping is needed, otherwise inevitable floating point inaccuracies can cause NaN
    const z0 = Math.acos(clamp(-1, 1, transformMatrix[0]));
    const z1 = Math.asin(clamp(-1, 1, transformMatrix[1]));
    return z1 > 0 ? z0 : -z0;
};
