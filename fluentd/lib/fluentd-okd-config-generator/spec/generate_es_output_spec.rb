require_relative 'spec_helper'

describe FluentdOKDConfigGenerator::Generator do

    describe "when generating elasticsearch output" do

        describe "it should generate an output match config" do
            before do
                generator = FluentdOKDConfigGenerator::Generator.new(logger())
                @results = generator.gen_output_label_match_confs(['logs.app'], {'logs.app'=>'**_foo_bar** **_xyz_abc**'})
            end
            it 'should produce well formed source label configs' do
                matches = @results[0]
                matches.must_equal '<match **_foo_bar** **_xyz_abc**>
    @type relabel
    @label @LOGS_APP
</match>
'
            end
        end
        describe "for an insecure endpoint" do
            # logs.app:
            # - type: “elasticsearch”
            #   endpoint: elasticsearch-apps:9200
            before do
                targets = [
                            {
                                'type': 'elasticsearch',
                                endpoint: 'es.svc.messaging.cluster.local:9654',
                            }
                        ]
                generator = FluentdOKDConfigGenerator::Generator.new(logger())
                @results = generator.gen_output_conf('logs.app', targets)
            end
            it 'should produce well formed source label configs' do
                source_label = @results [:source_labels][0]
                source_label.must_equal '<label @LOGS_APP>
    <match **>
        @type copy
        <store>
            @type relabel
            @label @LOGS_APP_ELASTICSEARCH0
        </store>
    </match>
</label>
'
            end
            it 'should produce a well formed endpoint label configs' do
                endpoint_label = @results [:endpoints][0]
                endpoint_label.must_equal '<label @LOGS_APP_ELASTICSEARCH0>
    <match retry_logs_app>
        @type copy
        <store>
            @type elasticsearch
            @id retry_logs_app_elasticsearch0
            host "es.svc.messaging.cluster.local"
            port "9654"
            scheme http
            target_index_key viaq_index_name
            id_key viaq_msg_id
            remove_keys viaq_index_name
            user fluentd
            password changeme
            type_name com.redhat.viaq.common
            write_operation "create"
            reload_connections "#{ENV[\'ES_RELOAD_CONNECTIONS\'] || \'true\'}"
            # https://github.com/uken/fluent-plugin-elasticsearch#reload-after
            reload_after "#{ENV[\'ES_RELOAD_AFTER\'] || \'200\'}"
            # https://github.com/uken/fluent-plugin-elasticsearch#sniffer-class-name
            sniffer_class_name "#{ENV[\'ES_SNIFFER_CLASS_NAME\'] || \'Fluent::Plugin::ElasticsearchSimpleSniffer\'}"
            reload_on_failure false
            # 2 ^ 31
            request_timeout 2147483648
            <buffer>
                @type file
                path \'/var/lib/fluentd/retry_logs_app_elasticsearch0\'
                flush_interval "#{ENV[\'ES_FLUSH_INTERVAL\'] || \'1s\'}"
                flush_thread_count "#{ENV[\'ES_FLUSH_THREAD_COUNT\'] || 2}"
                flush_at_shutdown "#{ENV[\'FLUSH_AT_SHUTDOWN\'] || \'false\'}"
                retry_max_interval "#{ENV[\'ES_RETRY_WAIT\'] || \'300\'}"
                retry_forever true
                queued_chunks_limit_size "#{ENV[\'BUFFER_QUEUE_LIMIT\'] || \'32\' }"
                chunk_limit_size "#{ENV[\'BUFFER_SIZE_LIMIT\'] || \'8m\' }"
                overflow_action "#{ENV[\'BUFFER_QUEUE_FULL_ACTION\'] || \'block\'}"
            </buffer>
        </store>
    </match>
    <match **>
        @type copy
        <store>
            @type elasticsearch
            @id logs_app_elasticsearch0
            host "es.svc.messaging.cluster.local"
            port "9654"
            scheme http
            target_index_key viaq_index_name
            id_key viaq_msg_id
            remove_keys viaq_index_name
            user fluentd
            password changeme
            type_name com.redhat.viaq.common
            retry_tag "retry_logs_app"
            write_operation "create"
            reload_connections "#{ENV[\'ES_RELOAD_CONNECTIONS\'] || \'true\'}"
            # https://github.com/uken/fluent-plugin-elasticsearch#reload-after
            reload_after "#{ENV[\'ES_RELOAD_AFTER\'] || \'200\'}"
            # https://github.com/uken/fluent-plugin-elasticsearch#sniffer-class-name
            sniffer_class_name "#{ENV[\'ES_SNIFFER_CLASS_NAME\'] || \'Fluent::Plugin::ElasticsearchSimpleSniffer\'}"
            reload_on_failure false
            # 2 ^ 31
            request_timeout 2147483648
            <buffer>
                @type file
                path \'/var/lib/fluentd/logs_app_elasticsearch0\'
                flush_interval "#{ENV[\'ES_FLUSH_INTERVAL\'] || \'1s\'}"
                flush_thread_count "#{ENV[\'ES_FLUSH_THREAD_COUNT\'] || 2}"
                flush_at_shutdown "#{ENV[\'FLUSH_AT_SHUTDOWN\'] || \'false\'}"
                retry_max_interval "#{ENV[\'ES_RETRY_WAIT\'] || \'300\'}"
                retry_forever true
                queued_chunks_limit_size "#{ENV[\'BUFFER_QUEUE_LIMIT\'] || \'32\' }"
                chunk_limit_size "#{ENV[\'BUFFER_SIZE_LIMIT\'] || \'8m\' }"
                overflow_action "#{ENV[\'BUFFER_QUEUE_FULL_ACTION\'] || \'block\'}"
            </buffer>
        </store>
    </match>
</label>'
            end
        end
    describe "for a secure endpoint" do
        before do
            #   certificates:
            #     secretName: my-elasticsearch-secret      
            targets = [
                        {
                            type: 'elasticsearch',
                            endpoint: 'es.svc.messaging.cluster.local:9654',
                            tls_cert: '/var/run/ocp-collector/secrets/my-es-secret/cert',
                            tls_cacert: '/var/run/ocp-collector/secrets/my-es-secret/cacert',
                            tls_key: '/var/run/ocp-collector/secrets/my-es-secret/key'
                        }
                    ]
            generator = FluentdOKDConfigGenerator::Generator.new(logger())
            @results = generator.gen_output_conf('logs.app', targets)
        end

        it 'should produce well formed source label configs' do
            source_label = @results [:source_labels][0]
            source_label.must_equal '<label @LOGS_APP>
    <match **>
        @type copy
        <store>
            @type relabel
            @label @LOGS_APP_ELASTICSEARCH0
        </store>
    </match>
</label>
'
        end 

        it 'should produce a well formed endpoint label configs' do
            endpoint_label = @results [:endpoints][0]
            endpoint_label.must_equal '<label @LOGS_APP_ELASTICSEARCH0>
    <match retry_logs_app>
        @type copy
        <store>
            @type elasticsearch
            @id retry_logs_app_elasticsearch0
            host "es.svc.messaging.cluster.local"
            port "9654"
            scheme https
            ssl_version TLSv1_2
            target_index_key viaq_index_name
            id_key viaq_msg_id
            remove_keys viaq_index_name
            user fluentd
            password changeme
            client_key "/var/run/ocp-collector/secrets/my-es-secret/key"
            client_cert "/var/run/ocp-collector/secrets/my-es-secret/cert"
            ca_file "/var/run/ocp-collector/secrets/my-es-secret/cacert"
            type_name com.redhat.viaq.common
            write_operation "create"
            reload_connections "#{ENV[\'ES_RELOAD_CONNECTIONS\'] || \'true\'}"
            # https://github.com/uken/fluent-plugin-elasticsearch#reload-after
            reload_after "#{ENV[\'ES_RELOAD_AFTER\'] || \'200\'}"
            # https://github.com/uken/fluent-plugin-elasticsearch#sniffer-class-name
            sniffer_class_name "#{ENV[\'ES_SNIFFER_CLASS_NAME\'] || \'Fluent::Plugin::ElasticsearchSimpleSniffer\'}"
            reload_on_failure false
            # 2 ^ 31
            request_timeout 2147483648
            <buffer>
                @type file
                path \'/var/lib/fluentd/retry_logs_app_elasticsearch0\'
                flush_interval "#{ENV[\'ES_FLUSH_INTERVAL\'] || \'1s\'}"
                flush_thread_count "#{ENV[\'ES_FLUSH_THREAD_COUNT\'] || 2}"
                flush_at_shutdown "#{ENV[\'FLUSH_AT_SHUTDOWN\'] || \'false\'}"
                retry_max_interval "#{ENV[\'ES_RETRY_WAIT\'] || \'300\'}"
                retry_forever true
                queued_chunks_limit_size "#{ENV[\'BUFFER_QUEUE_LIMIT\'] || \'32\' }"
                chunk_limit_size "#{ENV[\'BUFFER_SIZE_LIMIT\'] || \'8m\' }"
                overflow_action "#{ENV[\'BUFFER_QUEUE_FULL_ACTION\'] || \'block\'}"
            </buffer>
        </store>
    </match>
    <match **>
        @type copy
        <store>
            @type elasticsearch
            @id logs_app_elasticsearch0
            host "es.svc.messaging.cluster.local"
            port "9654"
            scheme https
            ssl_version TLSv1_2
            target_index_key viaq_index_name
            id_key viaq_msg_id
            remove_keys viaq_index_name
            user fluentd
            password changeme
            client_key "/var/run/ocp-collector/secrets/my-es-secret/key"
            client_cert "/var/run/ocp-collector/secrets/my-es-secret/cert"
            ca_file "/var/run/ocp-collector/secrets/my-es-secret/cacert"
            type_name com.redhat.viaq.common
            retry_tag "retry_logs_app"
            write_operation "create"
            reload_connections "#{ENV[\'ES_RELOAD_CONNECTIONS\'] || \'true\'}"
            # https://github.com/uken/fluent-plugin-elasticsearch#reload-after
            reload_after "#{ENV[\'ES_RELOAD_AFTER\'] || \'200\'}"
            # https://github.com/uken/fluent-plugin-elasticsearch#sniffer-class-name
            sniffer_class_name "#{ENV[\'ES_SNIFFER_CLASS_NAME\'] || \'Fluent::Plugin::ElasticsearchSimpleSniffer\'}"
            reload_on_failure false
            # 2 ^ 31
            request_timeout 2147483648
            <buffer>
                @type file
                path \'/var/lib/fluentd/logs_app_elasticsearch0\'
                flush_interval "#{ENV[\'ES_FLUSH_INTERVAL\'] || \'1s\'}"
                flush_thread_count "#{ENV[\'ES_FLUSH_THREAD_COUNT\'] || 2}"
                flush_at_shutdown "#{ENV[\'FLUSH_AT_SHUTDOWN\'] || \'false\'}"
                retry_max_interval "#{ENV[\'ES_RETRY_WAIT\'] || \'300\'}"
                retry_forever true
                queued_chunks_limit_size "#{ENV[\'BUFFER_QUEUE_LIMIT\'] || \'32\' }"
                chunk_limit_size "#{ENV[\'BUFFER_SIZE_LIMIT\'] || \'8m\' }"
                overflow_action "#{ENV[\'BUFFER_QUEUE_FULL_ACTION\'] || \'block\'}"
            </buffer>
        </store>
    </match>
</label>'
        end
        end
    end
end
