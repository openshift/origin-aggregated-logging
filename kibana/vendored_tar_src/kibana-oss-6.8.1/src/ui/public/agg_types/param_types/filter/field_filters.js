/**
 * A registry to store {@link AggTypeFieldFilter} which are used to filter down
 * available fields for a specific visualization and {@link AggType}.
 */
var AggTypeFieldFilters = /** @class */ (function () {
    function AggTypeFieldFilters() {
        this.filters = new Set();
    }
    /**
     * Register a new {@link AggTypeFieldFilter} with this registry.
     * This will be used by the {@link #filter|filter method}.
     *
     * @param filter The filter to register.
     */
    AggTypeFieldFilters.prototype.addFilter = function (filter) {
        this.filters.add(filter);
    };
    /**
     * Returns the {@link any|fields} filtered by all registered filters.
     *
     * @param fields A list of fields that will be filtered down by this registry.
     * @param fieldParamType The fieldParamType for which the returning list will be used.
     * @param indexPattern The indexPattern for which the returning list will be used.
     * @param aggConfig The aggConfig for which the returning list will be used.
     * @return A filtered list of the passed fields.
     */
    AggTypeFieldFilters.prototype.filter = function (fields, fieldParamType, aggConfig, vis) {
        var allFilters = Array.from(this.filters);
        var allowedAggTypeFields = fields.filter(function (field) {
            var isAggTypeFieldAllowed = allFilters.every(function (filter) {
                return filter(field, fieldParamType, aggConfig, vis);
            });
            return isAggTypeFieldAllowed;
        });
        return allowedAggTypeFields;
    };
    return AggTypeFieldFilters;
}());
var aggTypeFieldFilters = new AggTypeFieldFilters();
export { aggTypeFieldFilters, AggTypeFieldFilters };
