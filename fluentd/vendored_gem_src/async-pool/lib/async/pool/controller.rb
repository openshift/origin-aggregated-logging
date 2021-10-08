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

require 'async'
require 'async/notification'
require 'async/semaphore'

module Async
	module Pool
		class Controller
			def self.wrap(**options, &block)
				self.new(block, **options)
			end
			
			def initialize(constructor, limit: nil)
				# All available resources:
				@resources = {}
				
				# Resources which may be available to be acquired:
				# This list may contain false positives, or resources which were okay but have since entered a state which is unusuable.
				@available = []
				
				@notification = Async::Notification.new
				
				@limit = limit
				
				@constructor = constructor
				@guard = Async::Semaphore.new(1)
				
				@gardener = nil
			end
			
			# @attribute [Hash(Resource, Integer)] all allocated resources, and their associated usage.
			attr :resources
			
			def size
				@resources.size
			end
			
			# Whether the pool has any active resources.
			def active?
				!@resources.empty?
			end
			
			# Whether there are resources which are currently in use.
			def busy?
				@resources.collect do |_, usage|
					return true if usage > 0
				end
				
				return false
			end
			
			# Whether there are available resources, i.e. whether {#acquire} can reuse an existing resource.
			def available?
				@available.any?
			end
			
			# Wait until a pool resource has been freed.
			def wait
				@notification.wait
			end
			
			def empty?
				@resources.empty?
			end
			
			def acquire
				resource = wait_for_resource
				
				return resource unless block_given?
				
				begin
					yield resource
				ensure
					release(resource)
				end
			end
			
			# Make the resource resources and let waiting tasks know that there is something resources.
			def release(resource)
				processed = false
				
				# A resource that is not good should also not be reusable.
				if resource.reusable?
					processed = reuse(resource)
				end
			ensure
				retire(resource) unless processed
			end
			
			def close
				@available.clear
				
				@resources.each_key(&:close)
				@resources.clear
				
				@gardener&.stop
			end
			
			def to_s
				if @resources.empty?
					"\#<#{self.class}(#{usage_string})>"
				else
					"\#<#{self.class}(#{usage_string}) #{availability_string}>"
				end
			end
			
			# Retire (and close) all unused resources. If a block is provided, it should implement the desired functionality for unused resources.
			# @param retain [Integer] the minimum number of resources to retain.
			# @yield resource [Resource] unused resources.
			def prune(retain = 0)
				unused = []
				
				@resources.each do |resource, usage|
					if usage.zero?
						unused << resource
					end
				end
				
				unused.each do |resource|
					if block_given?
						yield resource
					else
						retire(resource)
					end
					
					break if @resources.size <= retain
				end
				
				# Update availability list:
				@available.clear
				@resources.each do |resource, usage|
					if usage < resource.concurrency and resource.reusable?
						@available << resource
					end
				end
				
				return unused.size
			end
			
			def retire(resource)
				Console.logger.debug(self) {"Retire #{resource}"}
				
				@resources.delete(resource)
				
				resource.close
				
				@notification.signal
				
				return true
			end
			
			protected
			
			def start_gardener
				return if @gardener
				
				Async(transient: true, annotation: "#{self.class} Gardener") do |task|
					@gardener = task
					
					Task.yield
				ensure
					@gardener = nil
					self.close
				end
			end
			
			def usage_string
				"#{@resources.size}/#{@limit || '∞'}"
			end
			
			def availability_string
				@resources.collect do |resource,usage|
					"#{usage}/#{resource.concurrency}#{resource.viable? ? nil : '*'}/#{resource.count}"
				end.join(";")
			end
			
			def usage
				@resources.count{|resource, usage| usage > 0}
			end
			
			def free
				@resources.count{|resource, usage| usage == 0}
			end
			
			# @returns [Boolean] Whether the number of available resources is excessive and we should retire some.
			def overflowing?
				if @resources.any?
					(self.free.to_f / @resources.size) > 0.5
				end
			end
			
			def reuse(resource)
				Console.logger.debug(self) {"Reuse #{resource}"}
				usage = @resources[resource]
				
				if usage.zero?
					raise "Trying to reuse unacquired resource: #{resource}!"
				end
				
				# We retire resources when adding to the @available list would overflow our pool:
				if usage == 1
					if overflowing?
						return retire(resource)
					end
				end
				
				# If the resource was fully utilized, it now becomes available:
				if usage == resource.concurrency
					@available.push(resource)
				end
				
				@resources[resource] = usage - 1
				
				@notification.signal
				
				return true
			end
			
			def wait_for_resource
				# If we fail to create a resource (below), we will end up waiting for one to become resources.
				until resource = available_resource
					@notification.wait
				end
				
				Console.logger.debug(self) {"Wait for resource -> #{resource}"}
				
				# if resource.concurrency > 1
				# 	@notification.signal
				# end
				
				return resource
			end
			
			# @returns [Object] A new resource in a "used" state.
			def create_resource
				self.start_gardener
				
				# This might return nil, which means creating the resource failed.
				if resource = @constructor.call
					@resources[resource] = 1
					
					# Make the resource available if it can be used multiple times:
					if resource.concurrency > 1
						@available.push(resource)
					end
				end
				
				return resource
			end
			
			# @returns [Object] An existing resource in a "used" state.
			def available_resource
				resource = nil
				
				@guard.acquire do
					resource = get_resource
				end
				
				return resource
			rescue Exception
				reuse(resource) if resource
				raise
			end
			
			private def get_resource
				while resource = @available.last
					if usage = @resources[resource] and usage < resource.concurrency
						if resource.viable?
							usage = (@resources[resource] += 1)
							
							if usage == resource.concurrency
								# The resource is used up to it's limit:
								@available.pop
							end
							
							return resource
						else
							retire(resource)
							@available.pop
						end
					else
						# The resource has been removed already, so skip it and remove it from the availability list.
						@available.pop
					end
				end
				
				if @limit.nil? or @resources.size < @limit
					Console.logger.debug(self) {"No available resources, allocating new one..."}
					
					return create_resource
				end
			end
		end
	end
end
