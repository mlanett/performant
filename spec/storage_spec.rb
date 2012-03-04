# -*- encoding: utf-8 -*-
require "helper"

describe Performant::Storage, redis: true, redis_configuration: true do

  subject { Performant.storage }

  it "should sample the counters" do
    subject.sample.should eq( { jobs: 0, busy: 0.0, work: 0.0 } )

    now = Time.at( 1330220626 )
    subject.record_start( "test", time: now )
    subject.sample.should eq( { jobs: 1, busy: 0.0, work: 0.0 } )
  end

  it "should record start events" do
    now = Time.at( 1330220626 )
    subject.record_start( "test", time: now )
    subject.sample[:jobs].should eq( 1 )
  end

  it "should record one operation" do
    now = Time.at( 1330220626 )
    subject.record_start( "test", time: now )
    subject.record_finish( "test", time: now + 1 )
    subject.sample.should eq( { jobs: 0, busy: 1.0, work: 1.0 } )
  end

  it "should record sequential operations" do
    now = Time.at( 1330220626 )
    subject.record_start( "test", time: now )
    subject.record_finish( "test", time: now + 1 )
    subject.record_start( "test", time: now + 2 )
    subject.record_finish( "test", time: now + 3 )
    subject.sample.should eq( { jobs: 0, busy: 2.0, work: 2.0 } )
  end

  it "should record multiple overlapping operations" do
    now = Time.at( 1330220626 )
    subject.record_start( "alpha", time: now )
    subject.record_start( "beta", time: now + 1 )
    subject.record_finish( "alpha", time: now + 2 )
    subject.record_finish( "beta", time: now + 3 )
    subject.sample.should eq( { jobs: 0, busy: 3.0, work: 4.0 } )
  end

  it "prohibits recording endpoints out of order"

end
