# -*- encoding: utf-8 -*-

require "helper"

describe Performant::Storage, redis: true do

  let(:configuration) { Performant::Configuration.new.tap { |c| c.redis_options = RedisHelper::TEST_REDIS } }
  subject { configuration.storage }

  it "should record one operation" do
    now = Time.at( 1330220626 )
    subject.record( :start, now )
    redis.get( "performant:operations" ).should eq("1")
    subject.record( :finish, now + 1 )
    redis.get( "performant:operations" ).should eq("0")
    redis.get( "performant:busy_time_f" ).should eq("1.0")
    redis.get( "performant:last_tick_f" ).should eq("1330220627.0")
    redis.get( "performant:work_time_f" ).should eq("1.0")
  end

  it "should record multiple overlapping operations" do
    now = Time.at( 1330220626 )
    subject.record( :start, now )
    redis.get( "performant:operations" ).should eq("1")
    subject.record( :start, now + 1 )
    redis.get( "performant:operations" ).should eq("2")
    subject.record( :finish, now + 2 )
    redis.get( "performant:operations" ).should eq("1")
    subject.record( :finish, now + 3 )
    redis.get( "performant:operations" ).should eq("0")
    redis.get( "performant:busy_time_f" ).should eq("3.0")
    redis.get( "performant:last_tick_f" ).should eq("1330220629.0")
    redis.get( "performant:work_time_f" ).should eq("4.0")
  end

end
