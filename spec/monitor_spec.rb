# -*- encoding: utf-8 -*-
require "helper"

describe Performant::Monitor, redis: true, redis_configuration: true do

  subject { Performant.monitor("test") }

  it "records starts and stops" do
    subject.track do
      subject.storage.sample[:jobs].should eq(1)
    end
    subject.storage.sample[:jobs].should eq(0)
  end

end
