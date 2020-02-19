import { aggTypeFilters } from '../../../agg_types/filter';
import { propFilter } from '../../../filters/_prop_filter';
var filterByName = propFilter('name');
/**
 * This filter checks the defined aggFilter in the schemas of that visualization
 * and limits available aggregations based on that.
 */
aggTypeFilters.addFilter(function (aggType, indexPatterns, aggConfig) {
    var doesSchemaAllowAggType = filterByName([aggType], aggConfig.schema.aggFilter).length !== 0;
    return doesSchemaAllowAggType;
});
