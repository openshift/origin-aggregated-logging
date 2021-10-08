# Copyright, 2019, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

require_relative 'event/progress'
require_relative 'clock'

module Console
	class Progress
		def self.now
			Process.clock_gettime(Process::CLOCK_MONOTONIC)
		end
		
		def initialize(output, subject, total = 0, minimum_output_duration: 1.0)
			@output = output
			@subject = subject
			
			@start_time = Progress.now
			
			@last_output_time = nil
			@minimum_output_duration = 0.1
			
			@current = 0
			@total = total
		end
		
		attr :subject
		attr :current
		attr :total
		
		def duration
			Progress.now - @start_time
		end
		
		def progress
			@current.to_f / @total.to_f
		end
		
		def remaining
			@total - @current
		end
		
		def average_duration
			if @current > 0
				duration / @current
			end
		end
		
		def estimated_remaining_time
			if average_duration = self.average_duration
				average_duration * remaining
			end
		end
		
		def increment(amount = 1)
			@current += amount
			
			if output?
				@output.info(@subject, self) {Event::Progress.new(@current, @total)}
				@last_output_time = Progress.now
			end
			
			return self
		end
		
		def resize(total)
			@total = total
			
			@output.info(@subject, self) {Event::Progress.new(@current, @total)}
			@last_output_time = Progress.now
			
			return self
		end
		
		def mark(*arguments)
			@output.info(@subject, *arguments)
		end
		
		def to_s
			if estimated_remaining_time = self.estimated_remaining_time
				"#{@current}/#{@total} completed in #{Clock.formatted_duration(self.duration)}, #{Clock.formatted_duration(estimated_remaining_time)} remaining."
			else
				"#{@current}/#{@total} completed, waiting for estimate..."
			end
		end
		
		private
		
		def duration_since_last_output
			if @last_output_time
				Progress.now - @last_output_time
			end
		end
		
		def output?
			if remaining.zero?
				return true
			elsif duration = duration_since_last_output
				return duration > @minimum_output_duration
			else
				return true
			end
		end
	end
end
