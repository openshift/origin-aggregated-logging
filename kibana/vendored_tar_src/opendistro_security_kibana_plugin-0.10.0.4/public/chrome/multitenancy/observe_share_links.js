import {parse} from 'url';

/**
 * @DEPRECATED
 *
 *
 * A MutationObserver that we attach to the top_nav in order to
 * detect when the share links area is shown and then make
 * sure that the tenant parameter is added to each URL
 * @param $timeout
 * @param {String} userRequestedTenant
 */
export default function setupShareObserver($timeout, userRequestedTenant) {

    // Return if we for whatever reason don't have a tenant
    if (typeof userRequestedTenant === 'undefined') {
        return;
    }

    /**
     * Name of the query parameter that identifies the tenant
     * @type {string}
     */
    const tenantKey = 'security_tenant';

    // The global and the private tenants need to be mapped to their respective keyword
    if (userRequestedTenant === '') {
        userRequestedTenant = 'global';
    } else if (userRequestedTenant === '__user__') {
        userRequestedTenant = 'private';
    }

    const tenantKeyAndValue = tenantKey + '=' + userRequestedTenant;

    /**
     * The selector of the observed element
     * @type {string}
     */
    const elementSelector = '[data-test-subj="top-nav"]';

    /**
     * The element we are observing
     * @type {null|Node}
     */
    let element = null;

    // @todo This is just an extra sanity check,
    // but by checking the values in the input fields this is probably redundant.
    // Removing this would make it less sensitive to changes in Kibana HTML.
    // However, we're not using the URL anymore - maybe just check the host and pathname at least?
    let allowedFieldIds = ['originalIframeUrl', 'originalUrl', 'snapshotIframeUrl', 'snapshotUrl'];

    /**
     * The MutationObserver
     * @type {null|MutationObserver}
     */
    let observer = null;

    /**
     * Options for the MutationObserver
     * @type {{childList: boolean, subtree: boolean}}
     */
    let config = {
        childList: true,
        subtree: true,
    };

    /**
     * Callback for when the MutationObserver detects changes
     * @param mutationsList
     */
    let observerCallback = function (mutationsList) {
        let inputElements = element.querySelectorAll('input[type="text"]');
        if (!inputElements.length) {
            return;
        }

        for (let i = 0; i < inputElements.length; i++) {

            if (!inputElements[i].id && allowedFieldIds.indexOf(inputElements[i].id) === -1) {
                // Skipping if the current field isn't one of the predefined fields
                continue;
            }

            replaceInputValue(inputElements[i]);
        }

        // Since the values may change, e.g. when generating a short link,
        // we need to keep observing event after the initial change
        //observer.disconnect();
    };

    /**
     * Changes the value of an input to include the security_tenant
     * @param inputElement
     * @param tries
     */
    function replaceInputValue(inputElement, tries = 1) {
        let originalValue = inputElement.value;
        let fieldValue = originalValue;

        // When converting the url to a short URL for the first time,
        // the input's value will be empty. In this case we try
        // a couple of times until we hopefully have a value.
        if (! originalValue) {
            tries += 1;
            if (tries < 5) {
                $timeout(function() {
                    replaceInputValue(inputElement, tries++);
                }, 400);
            }

            return;
        }

        // We need to figure out where in the value to add the tenant.
        // Since Kibana sometimes adds values that aren't in the current location/url,
        // we need to use the actual input values to do a sanity check.
        try {

            // For the iFrame urls we need to parse out the src
            if (originalValue.toLowerCase().indexOf('<iframe') === 0) {
                const regex = /<iframe[^>]*src="([^"]*)"/i;
                let match = regex.exec(originalValue);
                if (match) {
                    fieldValue = match[1]; // Contains the matched src, [0] contains the string where the match was found
                }
            }

            let newValue = addTenantToURL(fieldValue, originalValue);

            if (newValue !== fieldValue) {
                inputElement.setAttribute('value', newValue);
            }
        } catch (error) {
            // Probably wasn't an url, so we just ignore this
        }
    }

    /**
     * Add the tenant the value. The originalValue may more than just an URL, e.g. for iFrame embeds.
     * @param url - The url we will append the tenant to
     * @param originalValue - In the case of iFrame embeds, we can't just replace the url itself
     * @returns {*}
     */
    function addTenantToURL(url, originalValue = null) {
        if (! originalValue) {
            originalValue = url;
        }

        let {host, pathname, search} = parse(url);
        let queryDelimiter = (!search) ? '?' : '&';

        // The url parser returns null if the search is empty. Change that to an empty
        // string so that we can use it to build the values later
        if (search === null) {
            search = '';
        } else if (search.toLowerCase().indexOf(tenantKey) > - 1) {
            // If we for some reason already have a tenant in the URL we skip any updates
            return originalValue;
        }

        // A helper for finding the part in the string that we want to extend/replace
        let valueToReplace = host + pathname + search;
        let replaceWith = valueToReplace + queryDelimiter + tenantKeyAndValue;

        return originalValue.replace(valueToReplace, replaceWith);
    }

    if ('MutationObserver' in window) {
        // Use a $timeout to avoid to wait for the view to be rendered
        $timeout(function () {
            element = document.querySelector(elementSelector);
            if (element) {
                observer = new MutationObserver(observerCallback);
                observer.observe(element, config);
            }

        });
    }
}