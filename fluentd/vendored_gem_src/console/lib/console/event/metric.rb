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

require_relative 'generic'
require_relative '../clock'

module Console
	module Event
		class Metric < Generic
			def self.[](**parameters)
				parameters.map(&self.method(:new))
			end
			
			def initialize(name, value, **tags)
				@name = name
				@value = value
				@tags = tags
			end
			
			attr :name
			attr :value
			attr :tags
			
			def to_h
				{name: @name, value: @value, tags: @tags}
			end
			
			def value_string
				"#{@name}: #{@value}"
			end
			
			def format(output, terminal, verbose)
				if @tags&.any?
					output.puts "#{value_string} #{@tags.inspect}"
				else
					output.puts value_string
				end
			end
		end
	end
end
