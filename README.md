# Zero::ParamsProcessor

[![Build Status](https://travis-ci.org/zhandao/zero-params_processor.svg?branch=test)](https://travis-ci.org/zhandao/zero-params_processor)
[![Maintainability](https://api.codeclimate.com/v1/badges/4d2fd3c04abf75a1158b/maintainability)](https://codeclimate.com/github/zhandao/zero-params_processor/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/4d2fd3c04abf75a1158b/test_coverage)](https://codeclimate.com/github/zhandao/zero-params_processor/test_coverage)

```ruby
# declare aop callback which provided by zpp
before_action :process_params!

# if you defined following spec in your api doc
# `query!` bang method means it's a required param
query! :time, Date, gt: '2018/1/1'.to_date, permit: true

# THEN in your controller action, you will get:
# 1. param validate: require, Date type and range
# 2. value convert: JSON has not Date type, you must
#	   do a convert from String, but it can do it for you:
params[:time] = params[:time].to_date # after some format checkers
# 3. set instance variable: allows you get the param by `@time`
#      instead of `params[:time]`
# 4. permitted: if you defined a lot of params with `permit: true`,
#      you will be allowed to get them by calling `permitted`, like:
Book.create(permitted)
```

## ONLY FOR the RAILS app that using Zero-Rails_OpenApi, like [Zero-Rails](https://github.com/zhandao/zero-rails)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'zero-params_processor'#, github: 'zhandao/zero-params_processor'
```

And then execute:

    $ bundle

## Usage

```ruby
before_action { process_params_by :validate!, :convert }
before_action :process_params! # all actions will be called
```
Action options: %i[ validate! convert set_instance_var set_permitted ]

### validate!

Check each input parameter based on `OpenApi.docs` (Zero-Rails_OpenApi's cattr), it will
raise `ParamsProcessor::ValidationFailed < StandardError` if check failed.

Note: If it did not find the corresponding open-api information in `OpenApi.docs`,
the check will be skipped.

### convert

Convert each input parameter to the specified type base on `OpenApi.docs`. For example:

We declare the parameter like this:
```ruby
query :price, Integer
query :like,  Boolean
query :time,  Date
```
In case params[:price] == `'1'`, the Converter will make it to be `1` (a Integer).  
In case params[:like] == `0`, the Converter will make it to be `false`.  
In case params[:time] == `'2018/1/1'`, the Converter will make it to be `Date.new(2018, 1, 1)`.  

### set_instance_var

Let (converted) input parameters to be instance variables of the current controller.

After that, you can access the params value like: `@price`, `@like`, `@time`.

### set_permitted

Permit the parameters that having `permit: true` attribute in `OpenApi.docs`. Like this:

```ruby
query :price, Integer, pmt: true
```

Then, the :price parameter will be permitted.

After this action, you can access all the permitted input via method `permitted`. Like:

```ruby
Book.create(permitted)
```

Note: `not_permit: true` attribute will lead to a slightly different behavior: All the
parameter that are not having `not_permit: true` will be permitted. For example:

```ruby
query :price, Integer
query :like, Boolean, npmt: true
query :time, Date
```

Then, the :price and :time will be permitted.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/zero-params_processor. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Zero::ParamsProcessor project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/zero-params_processor/blob/master/CODE_OF_CONDUCT.md).
