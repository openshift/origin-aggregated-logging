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

module Protocol
	module HTTP2
		DEFAULT_WEIGHT = 16
		
		class Dependency
			def self.create(connection, id, priority = nil)
				weight = DEFAULT_WEIGHT
				exclusive = false
				
				if priority
					if parent = connection.dependencies[priority.stream_dependency]
						exclusive = priority.exclusive
					end
					
					weight = priority.weight
				end
				
				if parent.nil?
					parent = connection.dependency
				end
				
				dependency = self.new(connection, id, weight)
				
				connection.dependencies[id] = dependency
				
				if exclusive
					parent.exclusive_child(dependency)
				else
					parent.add_child(dependency)
				end
				
				return dependency
			end
			
			def initialize(connection, id, weight = DEFAULT_WEIGHT)
				@connection = connection
				@id = id
				
				@parent = nil
				@children = nil
				
				@weight = weight
				
				# Cache of any associated stream:
				@stream = nil
				
				# Cache of children for window allocation:
				@total_weight = 0
				@ordered_children = nil
			end
			
			def <=> other
				@weight <=> other.weight
			end
			
			# The connection this stream belongs to.
			attr :connection
			
			# Stream ID (odd for client initiated streams, even otherwise).
			attr :id
			
			# The parent dependency.
			attr_accessor :parent
			
			# The dependent children.
			attr_accessor :children
			
			# The weight of the stream relative to other siblings.
			attr_accessor :weight
			
			def stream
				@stream ||= @connection.streams[@id]
			end
			
			def clear_cache!
				@ordered_children = nil
			end
			
			def delete!
				@connection.dependencies.delete(@id)
				
				@parent.remove_child(self)
				
				@children&.each do |id, child|
					parent.add_child(child)
				end
				
				@connection = nil
				@parent = nil
				@children = nil
			end
			
			def add_child(dependency)
				@children ||= {}
				@children[dependency.id] = dependency
				
				dependency.parent = self
				
				self.clear_cache!
			end
			
			def remove_child(dependency)
				@children&.delete(dependency.id)
				
				self.clear_cache!
			end
			
			# An exclusive flag allows for the insertion of a new level of dependencies.  The exclusive flag causes the stream to become the sole dependency of its parent stream, causing other dependencies to become dependent on the exclusive stream.
			# @param parent [Dependency] the dependency which will be inserted, taking control of all current children.
			def exclusive_child(parent)
				parent.children = @children
				
				@children&.each_value do |child|
					child.parent = parent
				end
				
				parent.clear_cache!
				
				@children = {parent.id => parent}
				self.clear_cache!
				
				parent.parent = self
			end
			
			def process_priority(priority)
				dependent_id = priority.stream_dependency
				
				if dependent_id == @id
					raise ProtocolError, "Stream priority for stream id #{@id} cannot depend on itself!"
				end
				
				@weight = priority.weight
				
				# We essentially ignore `dependent_id` if the dependency does not exist:
				if parent = @connection.dependencies[dependent_id]
					if priority.exclusive
						@parent.remove_child(self)
						
						parent.exclusive_child(self)
					elsif !@parent.equal?(parent)
						@parent.remove_child(self)
						
						parent.add_child(self)
					end
				end
			end
			
			# Change the priority of the stream both locally and remotely.
			def priority= priority
				send_priority(priority)
				process_priority(priority)
			end
			
			# The current local priority of the stream.
			def priority(exclusive = false)
				Priority.new(exclusive, @parent.id, @weight)
			end
			
			def send_priority(priority)
				@connection.send_priority(@id, priority)
			end
			
			def receive_priority(frame)
				self.process_priority(frame.unpack)
			end
			
			def total_weight
				self.orderd_children
				
				return @total_weight
			end
			
			def ordered_children
				unless @ordered_children
					if @children and !@children.empty?
						@ordered_children = @children.values.sort
						@total_weight = @ordered_children.sum(&:weight)
					end
				end
				
				return @ordered_children
			end
			
			# Traverse active streams in order of priority and allow them to consume the available flow-control window.
			# @param amount [Integer] the amount of data to write. Defaults to the current window capacity.
			def consume_window(size)
				# If there is an associated stream, give it priority:
				if stream = self.stream
					return if stream.window_updated(size)
				end
				
				# Otherwise, allow the dependent children to use up the available window:
				self.ordered_children&.each do |child|
					# Compute the proportional allocation:
					allocated = (child.weight * size) / @total_weight
					
					child.consume_window(allocated) if allocated > 0
				end
			end
			
			def to_s
				"\#<#{self.class} id=#{@id} parent id=#{@parent&.id} weight=#{@weight} #{@children&.size || 0} children>"
			end
			
			def print_hierarchy(buffer, indent: 0)
				buffer.puts "#{" " * indent}#{self}"
				@children&.each_value do |child|
					child.print_hierarchy(buffer, indent: indent+1)
				end
			end
		end
	end
end
