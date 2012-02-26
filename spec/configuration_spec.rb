# -*- encoding: utf-8 -*-

require "helper"

describe Performant::Configuration do

  subject { Performant::Configuration.new interval_size: 60 }

  it "should find the right interval" do
    # 1330220626 => 2012-02-25 17:43:46 -0800 
    subject.interval( 1330220626 ).should eq( Time.at(1330220580) ... Time.at(1330220640) )
  end

end
