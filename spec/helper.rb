# -*- encoding: utf-8 -*-
require "bundler/setup"         # set up gem paths
#equire "ruby-debug"
require "simplecov"             # code coverage
SimpleCov.start                 # must be loaded before our own code
require "rspec-redis_helper"    # for the redis support
require "performant"            # load this gem

RSpec.configure do |spec|
  spec.include RSpec::RedisHelper, redis: true

  # nuke the Redis database around each run
  spec.around( :each, redis: true ) do |example|
    with_clean_redis do
      example.run
    end
  end

  spec.around( :each, redis_configuration: true ) do |example|
    Performant::Configuration.set! redis: RSpec::RedisHelper::TEST
    example.call
  end

end
