/**
 * A registry to store {@link AggTypeFilter} which are used to filter down
 * available aggregations for a specific visualization and {@link AggConfig}.
 */
var AggTypeFilters = /** @class */ (function () {
    function AggTypeFilters() {
        this.filters = new Set();
    }
    /**
     * Register a new {@link AggTypeFilter} with this registry.
     *
     * @param filter The filter to register.
     */
    AggTypeFilters.prototype.addFilter = function (filter) {
        this.filters.add(filter);
    };
    /**
     * Returns the {@link AggType|aggTypes} filtered by all registered filters.
     *
     * @param aggTypes A list of aggTypes that will be filtered down by this registry.
     * @param indexPattern The indexPattern for which this list should be filtered down.
     * @param aggConfig The aggConfig for which the returning list will be used.
     * @return A filtered list of the passed aggTypes.
     */
    AggTypeFilters.prototype.filter = function (aggTypes, indexPattern, aggConfig) {
        var allFilters = Array.from(this.filters);
        var allowedAggTypes = aggTypes.filter(function (aggType) {
            var isAggTypeAllowed = allFilters.every(function (filter) { return filter(aggType, indexPattern, aggConfig); });
            return isAggTypeAllowed;
        });
        return allowedAggTypes;
    };
    return AggTypeFilters;
}());
var aggTypeFilters = new AggTypeFilters();
export { aggTypeFilters, AggTypeFilters };
