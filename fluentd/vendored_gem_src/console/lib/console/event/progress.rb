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

module Console
	module Event
		class Progress < Generic
			BLOCK = [
				" ",
				"▏",
				"▎",
				"▍",
				"▌",
				"▋",
				"▊",
				"▉",
				"█",
			]
			
			def initialize(current, total)
				@current = current
				@total = total
			end
			
			attr :current
			attr :total
			
			def value
				@current.to_f / @total.to_f
			end
			
			def bar(value = self.value, width = 70)
				blocks = width * value
				full_blocks = blocks.floor
				partial_block = ((blocks - full_blocks) * BLOCK.size).floor
				
				if partial_block.zero?
					BLOCK.last * full_blocks
				else
					"#{BLOCK.last * full_blocks}#{BLOCK[partial_block]}"
				end.ljust(width)
			end
			
			def self.register(terminal)
				terminal[:progress_bar] ||= terminal.style(:blue, :white)
			end
			
			def to_h
				{current: @current, total: @total}
			end
			
			def format(output, terminal, verbose)
				output.puts "#{terminal[:progress_bar]}#{self.bar}#{terminal.reset} #{sprintf('%6.2f', self.value * 100)}%"
			end
		end
	end
end
