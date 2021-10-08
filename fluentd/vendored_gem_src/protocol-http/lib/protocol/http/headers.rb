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

require_relative 'header/split'
require_relative 'header/multiple'
require_relative 'header/cookie'
require_relative 'header/connection'
require_relative 'header/cache_control'
require_relative 'header/etag'
require_relative 'header/etags'
require_relative 'header/vary'
require_relative 'header/authorization'

module Protocol
	module HTTP
		# Headers are an array of key-value pairs. Some header keys represent multiple values.
		class Headers
			Split = Header::Split
			Multiple = Header::Multiple
			
			TRAILER = 'trailer'
			
			# Construct an instance from a headers Array or Hash. No-op if already an instance of `Headers`. If the underlying array is frozen, it will be duped.
			# @return [Headers] an instance of headers.
			def self.[] headers
				if headers.nil?
					return self.new
				end
				
				if headers.is_a?(self)
					if headers.frozen?
						return headers.dup
					else
						return headers
					end
				end
				
				fields = headers.to_a
				
				if fields.frozen?
					fields = fields.dup
				end
				
				return self.new(fields)
			end
			
			def initialize(fields = [], indexed = nil)
				@fields = fields
				@indexed = indexed
				
				# Marks where trailer start in the @fields array.
				@tail = nil
			end
			
			def initialize_dup(other)
				super
				
				@fields = @fields.dup
				@indexed = @indexed.dup
			end
			
			def clear
				@fields.clear
				@indexed = nil
				@tail = nil
			end
			
			# Flatten trailer into the headers.
			def flatten!
				if @tail
					self.delete(TRAILER)
					@tail = nil
				end
				
				return self
			end
			
			def flatten
				self.dup.flatten!
			end
			
			# An array of `[key, value]` pairs.
			attr :fields
			
			# @return the trailer if there are any.
			def trailer?
				@tail != nil
			end
			
			# Record the current headers, and prepare to receive trailer.
			def trailer!(&block)
				return nil unless self.include?(TRAILER)
				
				@tail ||= @fields.size
				
				return to_enum(:trailer!) unless block_given?
				
				if @tail
					@fields.drop(@tail).each(&block)
				end
			end
			
			# Enumerate all headers in the trailer, if there are any.
			def trailer(&block)
				return to_enum(:trailer) unless block_given?
				
				if @tail
					@fields.drop(@tail).each(&block)
				end
			end
			
			def freeze
				return if frozen?
				
				# Ensure @indexed is generated:
				self.to_h
				
				@fields.freeze
				@indexed.freeze
				
				super
			end
			
			def empty?
				@fields.empty?
			end
			
			def each(&block)
				@fields.each(&block)
			end
			
			def include? key
				self[key] != nil
			end
			
			def keys
				self.to_h.keys
			end
			
			def extract(keys)
				deleted, @fields = @fields.partition do |field|
					keys.include?(field.first.downcase)
				end
				
				if @indexed
					keys.each do |key|
						@indexed.delete(key)
					end
				end
				
				return deleted
			end
			
			# Add the specified header key value pair.
			#
			# @param key [String] the header key.
			# @param value [String] the header value to assign.
			def add(key, value)
				self[key] = value
			end
			
			# Set the specified header key to the specified value, replacing any existing header keys with the same name.
			# @param key [String] the header key to replace.
			# @param value [String] the header value to assign.
			def set(key, value)
				# TODO This could be a bit more efficient:
				self.delete(key)
				self.add(key, value)
			end
			
			def merge!(headers)
				headers.each do |key, value|
					self[key] = value
				end
				
				return self
			end
			
			def merge(headers)
				self.dup.merge!(headers)
			end
			
			# Append the value to the given key. Some values can be appended multiple times, others can only be set once.
			# @param key [String] The header key.
			# @param value The header value.
			def []= key, value
				if @indexed
					merge_into(@indexed, key.downcase, value)
				end
				
				@fields << [key, value]
			end
			
			POLICY = {
				# Headers which may only be specified once.
				'content-type' => false,
				'content-disposition' => false,
				'content-length' => false,
				'user-agent' => false,
				'referer' => false,
				'host' => false,
				'if-modified-since' => false,
				'if-unmodified-since' => false,
				'from' => false,
				'location' => false,
				'max-forwards' => false,
				
				# Custom headers:
				'connection' => Header::Connection,
				'cache-control' => Header::CacheControl,
				'vary' => Header::Vary,
				
				# Headers specifically for proxies:
				'via' => Split,
				'x-forwarded-for' => Split,
				
				# Authorization headers:
				'authorization' => Header::Authorization,
				'proxy-authorization' => Header::Authorization,
				
				# Cache validations:
				'etag' => Header::ETag,
				'if-match' => Header::ETags,
				'if-none-match' => Header::ETags,
				
				# Headers which may be specified multiple times, but which can't be concatenated:
				'www-authenticate' => Multiple,
				'proxy-authenticate' => Multiple,
				
				# Custom headers:
				'set-cookie' => Header::SetCookie,
				'cookie' => Header::Cookie,
			}.tap{|hash| hash.default = Split}
			
			# Delete all headers with the given key, and return the merged value.
			def delete(key)
				deleted, @fields = @fields.partition do |field|
					field.first.downcase == key
				end
				
				if deleted.empty?
					return nil
				end
				
				if @indexed
					return @indexed.delete(key)
				elsif policy = POLICY[key]
					(key, value), *tail = deleted
					merged = policy.new(value)
					
					tail.each{|k,v| merged << v}
					
					return merged
				else
					key, value = deleted.last
					return value
				end
			end
			
			protected def merge_into(hash, key, value)
				if policy = POLICY[key]
					if current_value = hash[key]
						current_value << value
					else
						hash[key] = policy.new(value)
					end
				else
					# We can't merge these, we only expose the last one set.
					hash[key] = value
				end
			end
			
			def [] key
				to_h[key]
			end
			
			# A hash table of `{key, policy[key].map(values)}`
			def to_h
				@indexed ||= @fields.inject({}) do |hash, (key, value)|
					merge_into(hash, key.downcase, value)
					
					hash
				end
			end
			
			def inspect
				"#<#{self.class} #{@fields.inspect}>"
			end
			
			def == other
				case other
				when Hash
					to_h == other
				when Headers
					@fields == other.fields
				else
					@fields == other
				end
			end
			
			# Used for merging objects into a sequential list of headers. Normalizes header keys and values.
			class Merged
				include Enumerable
				
				def initialize(*all)
					@all = all
				end
				
				def clear
					@all.clear
				end
				
				def << headers
					@all << headers
					
					return self
				end
				
				# @yield [String, String] header key (lower case) and value (as string).
				def each(&block)
					@all.each do |headers|
						headers.each do |key, value|
							yield key.downcase, value.to_s
						end
					end
				end
			end
		end
	end
end
