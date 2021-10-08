# Copyright, 2018, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

require_relative 'frame'

module Protocol
	module HTTP2
		class Window
			# @param capacity [Integer] The initial window size, typically from the settings.
			def initialize(capacity = 0xFFFF)
				# This is the main field required:
				@available = capacity
				
				# These two fields are primarily used for efficiently sending window updates:
				@used = 0
				@capacity = capacity
			end
			
			# The window is completely full?
			def full?
				@available <= 0
			end
			
			attr :used
			attr :capacity
			
			# When the value of SETTINGS_INITIAL_WINDOW_SIZE changes, a receiver MUST adjust the size of all stream flow-control windows that it maintains by the difference between the new value and the old value.
			def capacity= value
				difference = value - @capacity
				@available += difference
				@capacity = value
			end
			
			def consume(amount)
				@available -= amount
				@used += amount
			end
			
			attr :available
			
			def available?
				@available > 0
			end
			
			def expand(amount)
				# puts "expand(#{amount}) @available=#{@available}"
				@available += amount
				@used -= amount
				
				if @available > MAXIMUM_ALLOWED_WINDOW_SIZE
					raise FlowControlError, "Expanding window by #{amount} caused overflow: #{@available} > #{MAXIMUM_ALLOWED_WINDOW_SIZE}!"
				end
			end
			
			def wanted
				@used
			end
			
			def limited?
				@available < (@capacity / 2)
			end
			
			def to_s
				"\#<Window used=#{@used} available=#{@available} capacity=#{@capacity}>"
			end
		end
		
		# This is a window which efficiently maintains a desired capacity.
		class LocalWindow < Window
			def initialize(capacity = 0xFFFF, desired: nil)
				super(capacity)
				
				@desired = desired
			end
			
			attr_accessor :desired
			
			def wanted
				if @desired
					# We must send an update which allows at least @desired bytes to be sent.
					(@desired - @capacity) + @used
				else
					@used
				end
			end
			
			def limited?
				@available < ((@desired || @capacity) / 2)
			end
		end
		
		# The WINDOW_UPDATE frame is used to implement flow control.
		#
		# +-+-------------------------------------------------------------+
		# |R|              Window Size Increment (31)                     |
		# +-+-------------------------------------------------------------+
		#
		class WindowUpdateFrame < Frame
			TYPE = 0x8
			FORMAT = "N"
			
			def pack(window_size_increment)
				super [window_size_increment].pack(FORMAT)
			end
			
			def unpack
				super.unpack1(FORMAT)
			end
			
			def read_payload(stream)
				super
				
				if @length != 4
					raise FrameSizeError, "Invalid frame length: #{@length} != 4!"
				end
			end
			
			def apply(connection)
				connection.receive_window_update(self)
			end
		end
	end
end
