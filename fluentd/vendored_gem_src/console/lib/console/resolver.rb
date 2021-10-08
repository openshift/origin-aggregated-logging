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

require_relative 'filter'

module Console
	class Resolver
		# You can change the log level for different classes using CONSOLE_<LEVEL> env vars.
		#
		# e.g. `CONSOLE_WARN=Acorn,Banana CONSOLE_DEBUG=Cat` will set the log level for the classes Acorn and Banana to `warn` and Cat to `debug`. This overrides the default log level.
		#
		# You can enable all log levels for a given class by using `CONSOLE_ON=MyClass`. Similarly you can disable all logging using `CONSOLE_OFF=MyClass`.
		#
		# @parameter logger [Logger] A logger instance to set the logging levels on.
		# @parameter env [Hash] The environment to read levels from.
		#
		# @returns [Nil] If there were no custom logging levels specified in the environment.
		# @returns [Resolver] If there were custom logging levels, then the created resolver is returned.
		def self.default_resolver(logger, env = ENV)
			# Find all CONSOLE_<LEVEL> variables from environment:
			levels = logger.class::LEVELS
				.map{|label, level| [level, env["CONSOLE_#{label.upcase}"]&.split(',')]}
				.to_h
				.compact
			
			off_klasses = env['CONSOLE_OFF']&.split(',')
			on_klasses = env['CONSOLE_ON']&.split(',')
			
			resolver = nil
			
			# If we have any levels, then create a class resolver, and each time a class is resolved, set the log level for that class to the specified level:
			if on_klasses&.any?
				resolver ||= Resolver.new
				
				resolver.bind(on_klasses) do |klass|
					logger.enable(klass, logger.class::MINIMUM_LEVEL - 1)
				end
			end
			
			if off_klasses&.any?
				resolver ||= Resolver.new
				
				resolver.bind(off_klasses) do |klass|
					logger.disable(klass)
				end
			end
			
			levels.each do |level, names|
				resolver ||= Resolver.new
				
				resolver.bind(names) do |klass|
					logger.enable(klass, level)
				end
			end
			
			return resolver
		end
		
		def initialize
			@names = {}
			
			@trace_point = TracePoint.new(:class, &self.method(:resolve))
		end
		
		def bind(names, &block)
			names.each do |name|
				if klass = Object.const_get(name) rescue nil
					yield klass
				else
					@names[name] = block
				end
			end
			
			if @names.any?
				@trace_point.enable
			else
				@trace_point.disable
			end
		end
		
		def waiting?
			@trace_point.enabled?
		end
		
		def resolve(trace_point)
			if block = @names.delete(trace_point.self.to_s)
				block.call(trace_point.self)
			end
			
			if @names.empty?
				@trace_point.disable
			end
		end
	end
end
