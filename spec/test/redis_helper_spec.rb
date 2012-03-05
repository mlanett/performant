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

  it "should be able to watch stuff" do
    with_clean_redis do

      with_watch( redis, "foo" ) do
        other.set "foo", "interference"
        redis.multi do |r|
          r.set "foo", "my value"
        end
      end.should be_nil

      with_watch( redis, "foo" ) do
        # no interference
        redis.multi do |r|
          r.set "foo", "my value"
        end
      end.should eq(["OK"])

    end
  end

end
