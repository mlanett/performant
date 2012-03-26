# -*- encoding: utf-8 -*-
require "helper"
require "redis"

describe Redis, redis: true, redis_configuration: true do

  it "has hashes" do
    redis.mapped_hmset "foo", a: 1, b: 2
    redis.hgetall("foo").should eq({ "a" => "1", "b" => "2" })
  end

end
