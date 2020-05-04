import Promise from 'bluebird';
import elasticsearch from 'elasticsearch';

export default function (plugin, server) {

    const callAdminAsKibanaUser = server.plugins.elasticsearch.getCluster('admin').callWithInternalUser;
    const index = server.config().get('kibana.index');
    const mappings = server.getKibanaIndexMappingsDsl();

    function waitForElasticsearchGreen() {
        return new Promise((resolve) => {
            server.plugins.elasticsearch.status.once('green', resolve);
        });
    }

    async function setupIndexTemplate() {
        const adminCluster = server.plugins.elasticsearch.getCluster('admin');

        try {
            await callAdminAsKibanaUser('indices.putTemplate', {
                name: `kibana_index_template:${index}_*`,
                body: {
                    template: index+"_*",
                    settings: {
                        number_of_shards: 1,
                    },
                    mappings: server.getKibanaIndexMappingsDsl(),
                },
            });
        } catch (error) {
            server.log(['debug', 'setupIndexTemplate'], {
                tmpl: 'Error setting up indexTemplate for SavedObjects: <%= err.message %>',
                es: {
                    resp: error.body,
                    status: error.status,
                },
                err: {
                    message: error.message,
                    stack: error.stack,
                },
            });
            throw new adminCluster.errors.ServiceUnavailable();
        }
    }

    return {
        setupIndexTemplate: setupIndexTemplate,
        waitForElasticsearchGreen: waitForElasticsearchGreen
    };

}
