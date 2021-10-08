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

require_relative 'output'
require_relative 'filter'
require_relative 'measure'
require_relative 'progress'

require_relative 'resolver'
require_relative 'terminal/logger'
require_relative 'serialized/logger'

require 'fiber/local'

module Console
	class Logger < Filter[debug: 0, info: 1, warn: 2, error: 3, fatal: 4]
		extend Fiber::Local
		
		# Set the default log level based on `$DEBUG` and `$VERBOSE`.
		# You can also specify CONSOLE_LEVEL=debug or CONSOLE_LEVEL=info in environment.
		# https://mislav.net/2011/06/ruby-verbose-mode/ has more details about how it all fits together.
		def self.default_log_level(env = ENV)
			if level = env['CONSOLE_LEVEL']
				LEVELS[level.to_sym] || level.to_i
			elsif $DEBUG
				DEBUG
			elsif $VERBOSE.nil?
				WARN
			else
				INFO
			end
		end
		
		# Controls verbose output using `$VERBOSE`.
		def self.verbose?(env = ENV)
			!$VERBOSE.nil? || env['CONSOLE_VERBOSE']
		end
		
		def self.default_logger(output = $stderr, env = ENV, **options)
			if options[:verbose].nil?
				options[:verbose] = self.verbose?(env)
			end
			
			if options[:level].nil?
				options[:level] = self.default_log_level(env)
			end
			
			output = Output.new(output, env, **options)
			logger = self.new(output, **options)
			
			Resolver.default_resolver(logger)
			
			return logger
		end
		
		def self.local
			self.default_logger
		end
		
		DEFAULT_LEVEL = 1
		
		def initialize(output, **options)
			super(output, **options)
		end
		
		def progress(subject, total, **options)
			Progress.new(self, subject, total, **options)
		end
		
		def measure(subject, name = "block", **tags, &block)
			measure = Measure.new(self, subject, **tags)
			
			if block_given?
				return measure.duration(name, &block)
			else
				return measure
			end
		end
		
		def failure(subject, exception, *arguments, &block)
			fatal(subject, *arguments, Event::Failure.new(exception), &block)
		end
	end
end
