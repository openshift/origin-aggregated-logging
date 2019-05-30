"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
// The Annotation interface is based on annotation documents stored in the
// `.ml-annotations-6` index, accessed via the `.ml-annotations-[read|write]` aliases.
// Annotation document mapping:
// PUT .ml-annotations-6
// {
//   "mappings": {
//     "annotation": {
//       "properties": {
//         "annotation": {
//           "type": "text"
//         },
//         "create_time": {
//           "type": "date",
//           "format": "epoch_millis"
//         },
//         "create_username": {
//           "type": "keyword"
//         },
//         "timestamp": {
//           "type": "date",
//           "format": "epoch_millis"
//         },
//         "end_timestamp": {
//           "type": "date",
//           "format": "epoch_millis"
//         },
//         "job_id": {
//           "type": "keyword"
//         },
//         "modified_time": {
//           "type": "date",
//           "format": "epoch_millis"
//         },
//         "modified_username": {
//           "type": "keyword"
//         },
//         "type": {
//           "type": "keyword"
//         }
//       }
//     }
//   }
// }
// Alias
// POST /_aliases
// {
//     "actions" : [
//         { "add" : { "index" : ".ml-annotations-6", "alias" : ".ml-annotations-read" } },
//         { "add" : { "index" : ".ml-annotations-6", "alias" : ".ml-annotations-write" } }
//     ]
// }
const annotations_1 = require("../constants/annotations");
function isAnnotation(arg) {
    return (arg.timestamp !== undefined &&
        typeof arg.annotation === 'string' &&
        typeof arg.job_id === 'string' &&
        (arg.type === annotations_1.ANNOTATION_TYPE.ANNOTATION || arg.type === annotations_1.ANNOTATION_TYPE.COMMENT));
}
exports.isAnnotation = isAnnotation;
function isAnnotations(arg) {
    if (Array.isArray(arg) === false) {
        return false;
    }
    return arg.every((d) => isAnnotation(d));
}
exports.isAnnotations = isAnnotations;
