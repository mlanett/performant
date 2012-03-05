# -*- encoding: utf-8 -*-
require "helper"

describe Performant::Storage, redis: true, redis_configuration: true do

  subject { Performant.storage.kind("test") }

  it "should sample the counters" do
    subject.sample.should eq( { jobs: 0, busy: 0.0, work: 0.0 } )

    now = Time.at( 1330220626 )
    subject.record_start( "a", time: now )
    subject.sample.should eq( { jobs: 1, busy: 0.0, work: 0.0 } )
  end

  it "should record start events" do
    now = Time.at( 1330220626 )
    subject.record_start( "a", time: now )
    subject.sample[:jobs].should eq( 1 )
  end

  it "should record one operation" do
    now = Time.at( 1330220626 )
    subject.record_start( "a", time: now )
    subject.record_finish( "a", time: now+1 )
    subject.sample.should eq( { jobs: 0, busy: 1.0, work: 1.0 } )
  end

  it "should record sequential operations" do
    now = Time.at( 1330220626 )
    subject.record_start( "a", time: now )
    subject.record_finish( "a", time: now+1 )
    subject.record_start( "b", time: now+2 )
    subject.record_finish( "b", time: now+3 )
    subject.sample.should eq( { jobs: 0, busy: 2.0, work: 2.0 } )
  end

  it "should record multiple overlapping operations" do
    now = Time.at( 1330220626 )
    subject.record_start( "a", time: now )
    subject.record_start( "b", time: now+1 )
    subject.record_start( "c", time: now+2 )
    subject.record_finish( "c", time: now+3 )
    subject.record_finish( "a", time: now+4 )
    subject.record_finish( "b", time: now+5 )
    subject.sample.should eq( { jobs: 0, busy: 5.0, work: 9.0 } )
  end

  it "prohibits recording endpoints out of order" do
    now = Time.at( 1330220626 )
    subject.record_start( "a", time: now )
    expect { subject.record_start( "b", time: now-0.1 ) }.to_not raise_exception
    expect { subject.record_start( "c", time: now-1.1 ) }.to raise_exception
    # c does not get started, so do not finish it
    expect { subject.record_finish( "b", time: now+1 ) }.to_not raise_exception
    expect { subject.record_finish( "a", time: now+1 ) }.to_not raise_exception
    subject.sample.should eq( { jobs: 0, busy: 1.0, work: 2.0 } )
  end

  it "can sample and update" do
    now = Time.at( 1330220626 )

    subject.record_start( "a", time: now )
    subject.sample!( now+1 ).should eq( { jobs: 1, busy: 1.0, work: 1.0 } )

    subject.record_finish( "a", time: now+2 )
    subject.sample!( now+3 ).should eq( { jobs: 0, busy: 2.0, work: 2.0 } )
  end

end
