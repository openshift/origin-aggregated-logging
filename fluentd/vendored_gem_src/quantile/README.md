# Quantile

Ruby Implementation of Graham Cormode and S. Muthukrishnan's [Effective
Computation of Biased Quantiles over Data Streams][1] in ICDE’05.

## Installation

```bash
gem install quantile
```

## Usage

```ruby
require 'quantile'

estimator = Quantile::Estimator.new

# Record any amount of Numeric values
10_000.times do
  estimator.observe(rand)
end

# Retrieve the value of a given quantile
estimator.query(0.5)

# Retrieve the number of observations
estimator.observations

# Get the sum of all observed values.
estimator.sum
```

## Tests [![Build Status][2]][3]

```bash
# Install dependencies
gem install bundler
bundle install

# Run tests
rake test
```

## Resources

  * [Paper: Effective Computation of Biased Quantiles over Data Streams][1]

## Author

Matt T. Proud <[matt.proud@gmail.com](mailto:matt.proud@gmail.com)>

[1]: http://www.cs.rutgers.edu/~muthu/bquant.pdf
[2]: https://secure.travis-ci.org/matttproud/ruby_quantile_estimation.png?branch=master
[3]: http://travis-ci.org/matttproud/ruby_quantile_estimation
