# -*- encoding: utf-8 -*-
require "helper"

describe Redis, redis: true, redis_configuration: true do

  it "should be redis" do
    redis.should be_kind_of(Redis)
  end

  it "has sorted sets" do
    redis.zcard("foo").should eq(0)
    redis.zadd("foo", 2, "bar")
    redis.zadd("foo", 3, "goo")
    redis.zcard("foo").should eq(2)
    redis.zrange("foo", 0, 0).should eq(["bar"]) # 0th item = smallest item
    redis.zrangebyscore( "foo", 0, 1, limit: [0,1] ).should eq([])
    redis.zrangebyscore( "foo", 0, 2, limit: [0,1] ).should eq(["bar"])
  end

  it "can select by score" do
    redis.zadd "foo", 1, "a"
    redis.zadd "foo", 2, "b"
    redis.zadd "foo", 3, "c"
    # inclusive by default http://redis.io/commands/zrangebyscore
    redis.zrangebyscore( "foo", "-inf", 2 ).should eq(["a","b"])
    redis.zrangebyscore( "foo", "-inf", 2, limit: [0,1] ).should eq(["a"])
  end

end
