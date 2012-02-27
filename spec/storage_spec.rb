# -*- encoding: utf-8 -*-

require "helper"

describe Performant::Storage, redis: true, redis_configuration: true do

  subject { Performant.storage }

  it "should record one operation" do
    now = Time.at( 1330220626 )
    subject.record_endpoint( :start, now )
    redis.get( "performant:operations" ).should eq("1")
    subject.record_endpoint( :finish, now + 1 )
    redis.get( "performant:operations" ).should eq("0")
    redis.get( "performant:busy_time_f" ).should eq("1.0")
    redis.get( "performant:last_tick_f" ).should eq("1330220627.0")
    redis.get( "performant:work_time_f" ).should eq("1.0")
  end

  it "should record multiple overlapping operations" do
    now = Time.at( 1330220626 )
    subject.record_endpoint( :start, now )
    redis.get( "performant:operations" ).should eq("1")
    subject.record_endpoint( :start, now + 1 )
    redis.get( "performant:operations" ).should eq("2")
    subject.record_endpoint( :finish, now + 2 )
    redis.get( "performant:operations" ).should eq("1")
    subject.record_endpoint( :finish, now + 3 )
    redis.get( "performant:operations" ).should eq("0")
    redis.get( "performant:busy_time_f" ).should eq("3.0")
    redis.get( "performant:last_tick_f" ).should eq("1330220629.0")
    redis.get( "performant:work_time_f" ).should eq("4.0")
  end

end
