# frozen_string_literal: true

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

require_relative '../headers'

module Protocol
	module HTTP
		class Middleware
			module NotFound
				def self.close
				end
				
				def self.call(request)
					Response[404, Headers[], []]
				end
			end
			
			class Builder
				def initialize(default_app = NotFound)
					@use = []
					@app = default_app
				end
				
				def use(middleware, *arguments, &block)
					@use << proc {|app| middleware.new(app, *arguments, &block)}
				end
				
				ruby2_keywords(:use) if respond_to?(:ruby2_keywords, true)
				
				def run(app)
					@app = app
				end
				
				def to_app
					@use.reverse.inject(@app) {|app, use| use.call(app)}
				end
			end
			
			def self.build(&block)
				builder = Builder.new
				
				builder.instance_eval(&block)
				
				return builder.to_app
			end
		end
	end
end
