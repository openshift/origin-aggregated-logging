require_relative 'spec_helper'

describe FluentdOKDConfigGenerator::InputValidator do
    before do
        @validator = FluentdOKDConfigGenerator::InputValidator.new(logger())
    end

    describe 'when validate_file!' do

        it 'should error when nil' do
            proc {@validator.validate_file(:input_file, nil)}.must_raise FluentdOKDConfigGenerator::ConfigGeneratorError
        end

        it 'should error when does not exist' do
            File.stub :exists?, false do
                proc {@validator.validate_file(:input_file, '/foo/bar')}.must_raise FluentdOKDConfigGenerator::ConfigGeneratorError
            end
        end
        
    end
    
    describe 'when validate_int' do
        it 'should error when value is non-numeric' do
            proc {@validator.validate_int(:foo, 'bar')}.must_raise FluentdOKDConfigGenerator::ConfigGeneratorError
        end
        it 'should error when value is nil' do
            proc {@validator.validate_int(:foo, nil)}.must_raise FluentdOKDConfigGenerator::ConfigGeneratorError
        end
        it 'should error when value is zero' do
            proc {@validator.validate_int(:foo, 0)}.must_raise FluentdOKDConfigGenerator::ConfigGeneratorError
        end
    end

    describe 'when validate! with valid inputs' do
        it 'should not raise an exception' do
            File.stub :exists?, true do
               @validator.validate!({
                input_file: '/foo/bar',
                target_file: '/xyz/abc',
                max_targets: 3
               })
            end
        end
        it 'should not raise an exception when target_file undefined' do
            File.stub :exists?, true do
               @validator.validate!({
                input_file: '/foo/bar',
                target_file: FluentdOKDConfigGenerator::InputValidator::STDOUT
               })
            end
        end
    end

end