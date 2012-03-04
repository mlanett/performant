# -*- encoding: utf-8 -*-
require "bundler/setup"         # set up gem paths
require "simplecov"             # code coverage
SimpleCov.start                 # must be loaded before our own code
require "performant"            # load this gem
require "performant/test/redis_helper"

RSpec.configure do |spec|
  spec.include Performant::Test::RedisHelper, redis: true

  # nuke the Redis database around each run
  # @see https://www.relishapp.com/rspec/rspec-core/docs/hooks/around-hooks
  spec.around( :each, redis: true ) do |example|
    with_clean_redis do
      example.run
    end
  end

  spec.around( :each, redis_configuration: true ) do |example|
    Performant::Configuration.new( redis: Performant::Test::RedisHelper::TEST_REDIS ).default!
    example.call
  end

end
