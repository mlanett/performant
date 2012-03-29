# -*- encoding: utf-8 -*-
require "helper"

describe Performant::Sampler, redis: true, redis_configuration: true do

  let( :storage ) { Performant.storage("test") }
  subject { Performant.sampler(["test"]) }

  describe "when sampling" do

    it "can get a sample" do
      storage.get_sample.should eq( { jobs: 0, busy: 0.0, work: 0.0, starts: 0 } )
    end

    it "can save the current diff" do
      now = Time.at( 2000000000 )
      subject.sample!("test",now).should include( { jobs: 0, busy: 0.0, work: 0.0, starts: 0 } )
      storage.record_start( "a", time: now )
      storage.record_finish( "a", time: now+1 )
      storage.record_start( "b", time: now+2 )
      subject.sample!("test",now+3).should include( { jobs: 1, busy: 2.0, work: 2.0, starts: 2 } )
    end

    it "lists all monitored jobs"
    # Performant:Jobs              < Set < Job > >

  end # when sampling

end
