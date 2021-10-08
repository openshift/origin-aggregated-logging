# Copyright, 2017, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require_relative 'buffer'

module Console
	UNKNOWN = 'unknown'
	
	class Filter
		def self.[] **levels
			klass = Class.new(self)
			min_level, max_level = levels.values.minmax
			
			klass.instance_exec do
				const_set(:LEVELS, levels)
				const_set(:MINIMUM_LEVEL, min_level)
				const_set(:MAXIMUM_LEVEL, max_level)
				
				levels.each do |name, level|
					const_set(name.to_s.upcase, level)
					
					define_method(name) do |subject = nil, *arguments, **options, &block|
						if self.enabled?(subject, level)
							self.call(subject, *arguments, severity: name, **options, **@options, &block)
						end
					end
					
					define_method("#{name}!") do
						@level = level
					end
					
					define_method("#{name}?") do
						@level <= level
					end
				end
			end
			
			return klass
		end
		
		def initialize(output, verbose: true, level: self.class::DEFAULT_LEVEL, enabled: nil, **options)
			@output = output
			@verbose = verbose
			@level = level
			
			@subjects = {}
			
			@options = options
			
			if enabled
				enabled.each{|name| enable(name)}
			end
		end
		
		def with(level: @level, verbose: @verbose, **options)
			dup.tap do |logger|
				logger.level = level
				logger.verbose! if verbose
				logger.options = @options.merge(options)
			end
		end
		
		attr_accessor :output
		attr :verbose
		attr :level
		
		attr :subjects
		
		attr_accessor :options
		
		def level= level
			if level.is_a? Symbol
				@level = self.class::LEVELS[level]
			else
				@level = level
			end
		end
		
		def verbose!(value = true)
			@verbose = value
			@output.verbose!(value)
		end
		
		def off!
			@level = self.class::MAXIMUM_LEVEL + 1
		end
		
		def all!
			@level = self.class::MINIMUM_LEVEL - 1
		end
		
		# You can enable and disable logging for classes. This function checks if logging for a given subject is enabled.
		# @param subject [Object] the subject to check.
		def enabled?(subject, level = self.class::MINIMUM_LEVEL)
			if specific_level = @subjects[subject.class]
				return level >= specific_level
			end
			
			if level >= @level
				return true
			end
		end
		
		# Enable specific log level for the given class.
		# @param name [String, Class] The class to enable.
		def enable(subject, level = self.class::MINIMUM_LEVEL)
			unless subject.is_a?(Class)
				subject = subject.class
			end
			
			@subjects[subject] = level
		end
		
		# Disable specific logging for the specific class.
		# @param name [String, Class] The class to disable.
		def disable(subject)
			unless subject.is_a? Class
				subject = subject.class
			end
			
			@subjects.delete(subject)
		end
		
		def call(*arguments, **options, &block)
			@output.call(*arguments, **options, &block)
		end
	end
end
