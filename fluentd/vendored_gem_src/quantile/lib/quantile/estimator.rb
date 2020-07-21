# Copyright 2013 Matt T. Proud
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module Quantile
  #
  # Estimate quantile values efficiently where both the rank and the inaccuracy
  # allowance are known a priori.  This is accomplished via Graham Cormode and
  # S\. Muthukrishnan's Effective Computation of Biased Quantiles over Data
  # Streams in ICDE’05.
  #
  #
  # @note {Estimator} is not concurrency safe.
  #
  # @see http://www.cs.rutgers.edu/~muthu/bquant.pdf Effective Computation of
  #      Biased Quantiles over Data Streams
  #
  class Estimator
    #
    # Create a streaming quantile estimator.
    #
    # @param invariants [Quantile] The quantile estimation targets that are provided a priori.
    # @return [Estimator] An initialized {Estimator} for the given targets.
    #
    def initialize(*invariants)
      if invariants.empty?
        invariants = [Quantile.new(0.5, 0.05), Quantile.new(0.90, 0.01), Quantile.new(0.99, 0.001)]
      end

      @invariants = invariants
      @buffer = []
      @head = nil

      @observations, @sum = 0, 0
    end

    #
    # Get the quantile targets.
    #
    attr_accessor :invariants

    #
    # Get the number of observed values.
    #
    def observations
      flush
      @observations
    end

    #
    # Observe a sample value with this {Estimator}.
    #
    # @param value [Numeric] The value to catalog for later analysis.
    #
    def observe(value)
      @buffer << value
      if @buffer.size == BUFFER_SIZE
        flush
      end
      @observations += 1
      @sum += value
    end

    #
    # Returns the sum of all observed values.
    #
    def sum
      @sum
    end

    #
    # Get a quantile value for a given rank.
    #
    # @param rank [Float] The target quantile to retrieve.  It *must* be one of
    #                     the invariants provided in the constructor.
    #
    # @return [Numeric, nil]  The quantile value for the rank or nil if no
    #   observations are present.
    #
    def query(rank)
      flush

      current = @head
      return unless current

      mid_rank = (rank * @observations).floor
      max_rank = mid_rank + (invariant(mid_rank, @observations) / 2).floor

      rank = 0.0
      while current.successor
        rank += current.rank
        if rank + current.successor.rank + current.successor.delta > max_rank
          return current.value
        end

        current = current.successor
      end

      return current.value
    end

    private

    BUFFER_SIZE = 512

    class Sample < Struct.new(:value, :rank, :delta, :successor); end

    def flush
      return if @buffer.empty?
      @buffer.sort!
      replace_batch
      @buffer.clear
      compress
    end

    def replace_batch
      @head ||= record(@buffer.shift, 1, 0, nil)

      rank = 0.0
      current = @head

      @buffer.each do |s|
        if s < @head.value
          @head = record(s, 1, 0, @head)
        end

        while current.successor && current.successor.value < s
          rank += current.rank
          current = current.successor
        end

        if current.successor
          current.successor = record(s, 1, invariant(rank, @observations)-1, current.successor)
        else
          current.successor = record(s, 1, 0, nil)
        end
        current = current.successor
      end
    end

    def record(value, rank, delta, successor)
      return Sample.new(value, rank, delta, successor)
    end

    def invariant(rank, n)
      min = n + 1

      @invariants.each do |i|
        delta = i.delta(rank, n)
        if delta < min
          min = delta
        end
      end

      return min.floor
    end

    def compress
      rank = 0.0
      current = @head

      while current && current.successor
        if current.rank + current.successor.rank + current.successor.delta <= invariant(rank, @observations)
          removed = current.successor

          current.value = removed.value
          current.rank += removed.rank
          current.delta = removed.delta
          current.successor = removed.successor
        end

        rank += current.rank
        current = current.successor
      end
    end
  end
end
