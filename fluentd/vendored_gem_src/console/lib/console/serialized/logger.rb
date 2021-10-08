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

require_relative '../buffer'
require_relative '../filter'

require 'time'
require 'json'

module Console
	module Serialized
		class Logger
			def initialize(io = $stderr, format: JSON, verbose: false, **options)
				@io = io
				@start = Time.now
				@format = format
				@verbose = verbose
			end
			
			attr :io
			attr :start
			attr :format
			
			def verbose!(value = true)
				@verbose = true
			end
			
			def dump(record)
				@format.dump(record)
			end
			
			def call(subject = nil, *arguments, severity: UNKNOWN, **options, &block)
				record = {
					time: Time.now.iso8601,
					severity: severity,
					class: subject.class,
					oid: subject.object_id,
					pid: Process.pid,
				}
				
				if subject
					record[:subject] = subject
				end
				
				if arguments.any?
					record[:arguments] = arguments
				end
				
				if options.any?
					record[:options] = options
				end
				
				if block_given?
					if block.arity.zero?
						record[:message] = yield
					else
						buffer = StringIO.new
						yield buffer
						record[:message] = buffer.string
					end
				end
				
				@io.puts(self.dump(record))
			end
		end
	end
end
