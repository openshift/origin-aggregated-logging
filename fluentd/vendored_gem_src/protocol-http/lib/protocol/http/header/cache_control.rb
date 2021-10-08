# frozen_string_literal: true

# Copyright, 2020, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

require_relative 'split'

module Protocol
	module HTTP
		module Header
			class CacheControl < Split
				PRIVATE = 'private'
				PUBLIC = 'public'
				NO_CACHE = 'no-cache'
				NO_STORE = 'no-store'
				MAX_AGE = 'max-age'
				
				STATIC = 'static'
				DYNAMIC = 'dynamic'
				STREAMING = 'streaming'
				
				def initialize(value)
					super(value.downcase)
				end
				
				def << value
					super(value.downcase)
				end
				
				def static?
					self.include?(STATIC)
				end
				
				def dynamic?
					self.include?(DYNAMIC)
				end
				
				def streaming?
					self.include?(STREAMING)
				end
				
				def private?
					self.include?(PRIVATE)
				end
				
				def public?
					self.include?(PUBLIC)
				end
				
				def no_cache?
					self.include?(NO_CACHE)
				end
				
				def no_store?
					self.include?(NO_STORE)
				end
				
				def max_age
					if value = self.find{|value| value.start_with?(MAX_AGE)}
						_, age = value.split('=', 2)
						
						return Integer(age)
					end
				end
			end
		end
	end
end
