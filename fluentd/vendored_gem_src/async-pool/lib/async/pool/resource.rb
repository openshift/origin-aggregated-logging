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

require 'console/logger'

require 'async/notification'
require 'async/semaphore'

module Async
	module Pool
		# The basic interface required by a pool resource.
		class Resource
			# Constructs a resource.
			def self.call
				self.new
			end
			
			def initialize(concurrency = 1)
				@concurrency = concurrency
				@closed = false
				@count = 0
			end
			
			# @attr [Integer] The concurrency of this resource, 1 (singleplex) or more (multiplex).
			attr :concurrency
			
			# @attr [Integer] The number of times this resource has been used.
			attr :count
			
			# Whether this resource can be acquired.
			# @return [Boolean] whether the resource can actually be used.
			def viable?
				!@closed
			end
			
			# Whether the resource has been closed by the user.
			# @return [Boolean] whether the resource has been closed or has failed.
			def closed?
				@closed
			end
			
			# Close the resource explicitly, e.g. the pool is being closed.
			def close
				if @closed
					raise "Already closed!"
				end
				
				@closed = true
			end
			
			# Whether this resource can be reused. Used when releasing resources back into the pool.
			def reusable?
				!@closed
			end
		end
	end
end
