import _ from 'lodash';

export default function (originalHeaders, headersToKeep) {

    const normalizeHeader = function (header) {
        if (!header) {
            return '';
        }
        header = header.toString();
        return header.trim().toLowerCase();
    };

    const headersToKeepNormalized = headersToKeep.map(normalizeHeader);

    const originalHeadersNormalized = _.mapKeys(originalHeaders, function (headerValue, headerName) {
        return normalizeHeader(headerName);
    });

    return _.pick(originalHeaders, headersToKeepNormalized);
}
