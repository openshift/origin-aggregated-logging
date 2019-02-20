require_relative 'spec_helper'

describe FluentdOKDConfigGenerator::PipelineInputLoader do

    include FluentdOKDConfigGenerator::PipelineInputLoader
    describe 'sanitize_input' do
        it 'should truncate targets which exceed max_targets_per_source' do
            input = {
                    'logs.app' => {
                        targets: [
                            {
                                'foo': 'bar'
                            },
                            {
                                'xyz': 'abc'
                            }
                        ]
                    },
                    'logs.infra' => {
                        targets: [
                            {
                                'foo': 'bar'
                            }
                        ]
                    }
                } 
            sanitize_input!(input, 1, logger: logger())
            input['logs.app'][:targets].length.must_equal 1 
            input['logs.infra'][:targets].length.must_equal 1 
        end
        
    end
    describe 'load_pipeline_input' do
        
        it 'should symbolize the keys for the targets' do
            YAML.stub :load_file, 
                {
                    'logs.app' => {
                        'targets' =>[
                            {
                                'foo': 'bar'
                            }
                        ]
                        }
                } do
                input = load_pipeline_input('/some/file', logger: logger())
                input.key?('logs.app').must_equal true 
                input['logs.app'][:targets].wont_be_nil 
                input['logs.app'][:targets][0][:foo].wont_be_nil 
            end
        end

        it 'should remove sources with no targets' do
            YAML.stub :load_file, 
                {
                'logs.app' => nil
                } do
                input = load_pipeline_input('/some/file', logger: logger())
                input.key?('logs.app').must_equal false 
            end
        end
        it 'should remove sources when value is not a hash' do
            YAML.stub :load_file, 
                {
                'logs.app' => []
                } do
                input = load_pipeline_input('/some/file', logger: logger())
                input.key?('logs.app').must_equal false 
            end
        end
        it 'should remove sources with empty targets' do
            YAML.stub :load_file, 
                {
                    'logs.app' => {'targets' =>[] }
                } do
                input = load_pipeline_input('/some/file', logger: logger())
                input['logs.app'].must_be_nil 
            end
        end
        it 'should remove sources with nil targets' do
            YAML.stub :load_file, 
                {
                    'logs.app' => {'targets' =>nil }
                } do
                input = load_pipeline_input('/some/file', logger: logger())
                input['logs.app'].must_be_nil 
            end
        end
    end
end