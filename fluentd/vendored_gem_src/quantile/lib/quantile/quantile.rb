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
  # A known quantile rank invariant for {Estimator}.
  #
  # @note {Quantile} is concurrency-safe.
  #
  class Quantile
    include Comparable

    attr_reader :quantile
    attr_reader :inaccuracy

    #
    # Create a known quantile estimator invariant.
    #
    # @param quantile [Float] The target quantile value expressed along the
    #                         interval [0, 1].  For instance, 0.5, would
    #                         generate a precomputed median value and 0.99
    #                         would provide the 99th percentile.
    # @param inaccuracy [Float] The target error allowance expressed along the
    #                           interval [0, 1].  For instance, 0.05 sets an
    #                           error allowance of 5 percent and 0.001 of 0.1
    #                           percent.
    #
    # @return [Quantile] an initialized {Quantile} for the given targets.
    def initialize(quantile, inaccuracy)
      @quantile = quantile
      @inaccuracy = inaccuracy

      @coefficient_i  = (2.0 * inaccuracy) / (1.0 - quantile)
      @coefficient_ii = 2.0 * inaccuracy / quantile
    end

    def delta(rank, n)
      if rank <= (@quantile * n).floor
        return @coefficient_i * (n - rank)
      end

      return @coefficient_ii * rank
    end

    #
    # Compare the given other quantile.
    #
    # @return [Fixnum] -1, 0, +1 or nil depending on whether the other quantile
    # is less than, equal to, or greater than self. This is the basis for the
    # tests in Comparable.
    #
    def <=>(other)
      self.quantile <=> other.quantile && self.inaccuracy <=> other.inaccuracy
    end
  end
end
