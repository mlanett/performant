# -*- encoding: utf-8 -*-
require "helper"

describe Performant::Configuration do




  describe "buckets" do

    subject { Performant::Configuration.new interval_size: 60 }

    it "should find the right interval" do
      # 1330220626 => 2012-02-25 17:43:46 -0800
      subject.interval( 1330220626 ).should eq( Time.at(1330220580) ... Time.at(1330220640) )
    end

    it "should find the right buckets for a range" do
      # 1330220626 => 2012-02-25 17:43:46 -0800
      # 1330220837 => 2012-02-25 17:47:17 -0800
      subject.buckets( 1330220626, 1330220837 ).should eq([
        Time.at(1330220580), # 17:43:00
        Time.at(1330220640), # 17:44:00
        Time.at(1330220700), # 17:45:00
        Time.at(1330220760), # 17:46:00
        Time.at(1330220820)  # 17:47:00
      ])
    end

    it "should find the right buckets for an inclusive range" do
      # 1330220626 => 2012-02-25 17:43:46 -0800
      # 1330220700 => 2012-02-25 17:45:00
      subject.buckets( 1330220626, 1330220700 ).should eq([
        Time.at(1330220580), # 17:43:00
        Time.at(1330220640), # 17:44:00
        Time.at(1330220700)  # 17:45:00
      ])
    end

  end # buckets


end
