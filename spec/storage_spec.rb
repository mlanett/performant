# -*- encoding: utf-8 -*-
require "helper"

describe Performant::Storage, redis: true, redis_configuration: true do

  subject { Performant.storage("test") }

  describe "when monitoring" do

    it "should sample the counters" do
      subject.sample.should eq( { jobs: 0, busy: 0.0, work: 0.0, starts: 0 } )

      now = Time.at( 2000000000 )
      subject.record_start( "a", time: now )
      subject.sample.should eq( { jobs: 1, busy: 0.0, work: 0.0, starts: 1 } )
    end

    it "should record start events" do
      now = Time.at( 2000000000 )
      subject.record_start( "a", time: now )
      subject.sample[:jobs].should eq( 1 )
      subject.sample[:starts].should eq( 1 )
    end

    it "should handle repeated start events" do
      now = Time.at( 2000000000 )
      subject.record_start( "a", time: now )
      subject.record_start( "a", time: now+1 )
      subject.sample[:jobs].should eq( 1 )
    end

    it "should record one operation" do
      now = Time.at( 2000000000 )
      subject.record_start( "a", time: now )
      subject.record_finish( "a", time: now+1 )
      subject.sample.should eq( { jobs: 0, busy: 1.0, work: 1.0, starts: 1 } )
    end

    it "should record sequential operations" do
      now = Time.at( 2000000000 )
      subject.record_start( "a", time: now )
      subject.record_finish( "a", time: now+1 )
      subject.record_start( "b", time: now+2 )
      subject.record_finish( "b", time: now+3 )
      subject.sample.should eq( { jobs: 0, busy: 2.0, work: 2.0, starts: 2 } )
    end

    it "should record multiple overlapping operations" do
      now = Time.at( 2000000000 )
      subject.record_start( "a", time: now )
      subject.record_start( "b", time: now+1 )
      subject.record_start( "c", time: now+2 )
      subject.record_finish( "c", time: now+3 )
      subject.record_finish( "a", time: now+4 )
      subject.record_finish( "b", time: now+5 )
      subject.sample.should eq( { jobs: 0, busy: 5.0, work: 9.0, starts: 3 } )
    end

    it "prohibits recording endpoints out of order" do
      now = Time.at( 2000000000 )
      subject.record_start( "a", time: now )
      expect { subject.record_start( "b", time: now-0.1 ) }.to_not raise_exception
      expect { subject.record_start( "c", time: now-1.1 ) }.to raise_exception
      # c does not get started, so do not finish it
      expect { subject.record_finish( "b", time: now+1 ) }.to_not raise_exception
      expect { subject.record_finish( "a", time: now+1 ) }.to_not raise_exception
      subject.sample.should eq( { jobs: 0, busy: 1.0, work: 2.0, starts: 2 } )
    end

  end # when monitoring

  it "can sample and update" do
    now = Time.at( 2000000000 )

    subject.record_start( "a", time: now )
    subject.tick!( now+1 ).should include( { jobs: 1, busy: 1.0, work: 1.0 } )

    subject.record_finish( "a", time: now+2 )
    subject.tick!( now+3 ).should include( { jobs: 0, busy: 2.0, work: 2.0 } )
  end

  it "can show expired jobs" do
    now = Time.at 2000000000
    subject.record_start  "a", time: now, timeout: 10
    subject.record_start  "b", time: now, timeout: 20
    subject.record_start  "c", time: now, timeout: 20
    subject.record_finish "b", time: now+1
    now += 15
    subject.expired_jobs( time: now ).should eq(["a"])
  end

  it "can expire jobs" do
    now = Time.at 2000000000
    subject.record_start  "a", time: now, timeout: 10
    subject.record_start  "b", time: now, timeout: 50

    subject.expire_jobs( time: now+20 ).should == 1

    expect { subject.record_finish "a", time: now+30 }.to raise_exception
    subject.record_finish "b", time: now+40
  end

  it "can get and save a sample" do
    subject.get_sample.should eq( { jobs: 0, busy: 0.0, work: 0.0, starts: 0 } )
    subject.save_sample jobs: 1, busy: 2, work: 3, starts: 4
    subject.get_sample.should eq( { jobs: 1, busy: 2.0, work: 3.0, starts: 4 } )
  end

end
