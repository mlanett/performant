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
      now = Time.at( 1000000000 )
      subject.sample!("test",now).should eq( { jobs: 0, busy: 0.0, work: 0.0, starts: 0, job: "test" } )
      storage.record_start( "a", time: now )
      storage.record_finish( "a", time: now + 1 )
      subject.sample!("test").should eq( { jobs: 0, busy: 1.0, work: 1.0, starts: 1, job: "test" } )
    end

    it "lists all monitored jobs"
    # Performant:Jobs              < Set < Job > >

  end # when sampling

end
