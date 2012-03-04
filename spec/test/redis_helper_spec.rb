# -*- encoding: utf-8 -*-
require "helper"

describe Performant::Test::RedisHelper do

  include Performant::Test::RedisHelper

  it "should be redis" do
    redis.should be_kind_of(Redis)
  end

  it "should clean redis before and after" do
    redis.set "foo", "bar"
    with_clean_redis do
      redis.get("foo").should eq(nil)
      redis.set "foo", "bar"
    end
    redis.get("foo").should eq(nil)
  end

end
