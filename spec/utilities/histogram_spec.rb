# -*- encoding: utf-8 -*-
require "helper"
require "performant/utilities/histogram"

describe Performant::Utilities::Histogram do

  it "should work for a large range" do
    h = Performant::Utilities::Histogram.new min: 1.0, max: 6.0, buckets: 5
    h.process([1.9, 2.8, 3.1, 4.2, 4.4, 4.6, 4.7, 5.2, 5.5, 6.0]).should eq([1,1,1,4,3])
    h.process([0.9, 2.8, 3.1, 4.2, 4.4, 4.6, 4.7, 5.2, 5.5, 6.1]).should eq([1,1,1,4,3])
  end

  it "should work for a small range" do
    h = Performant::Utilities::Histogram.new min: 0.0, max: 1.0, buckets: 5
    h.process([0.9, 0.8, 0.1, 0.2, 0.4, 0.6, 0.7, 0.2, 0.5, 1.0]).should eq([1,2,2,2,3])
  end

end
