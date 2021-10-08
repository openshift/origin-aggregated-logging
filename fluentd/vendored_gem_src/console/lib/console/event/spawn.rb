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
		class Spawn < Generic
			def self.for(*arguments, **options)
				# Extract out the command environment:
				if arguments.first.is_a?(Hash)
					self.new(*arguments, **options)
				else
					self.new(nil, arguments, **options)
				end
			end
			
			def initialize(environment, *arguments, **options)
				@environment = environment
				@arguments = arguments
				@options = options
			end
			
			attr :environment
			attr :arguments
			attr :options
			
			def chdir_string(options)
				if options and chdir = options[:chdir]
					" in #{chdir}"
				end
			end
			
			def self.register(terminal)
				terminal[:shell_command] ||= terminal.style(:blue, nil, :bold)
			end
			
			def to_h
				{environment: @environment, arguments: @arguments, options: @options}
			end
			
			def format(output, terminal, verbose)
				arguments = @arguments.flatten.collect(&:to_s)
				
				output.puts "  #{terminal[:shell_command]}#{arguments.join(' ')}#{terminal.reset}#{chdir_string(options)}"
				
				if verbose and @environment
					@environment.each do |key, value|
						output.puts "    export #{key}=#{value}"
					end
				end
			end
		end
	end
	
	# Deprecated.
	Shell = Event::Spawn
end
