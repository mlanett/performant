# -*- encoding: utf-8 -*-
require "helper"

describe Performant::Configuration do

  describe "creation" do

    it "can be created" do
      c = Performant::Configuration.new interval_size: 5
      c.interval_size.should eq(5)
    end

    it "can be loaded" do
      c = Performant::Configuration.load src: File.expand_path( "../spec_10_0.yml", __FILE__ ), env: "test"
      c.interval_size.should eq(10)
    end

    it "can be set to default" do
      c = Performant::Configuration.load src: File.expand_path( "../spec_10_0.yml", __FILE__ ), env: "test"
      c.default!
      Performant::Configuration.default.interval_size.should eq(10)
    end

  end

  describe "factory" do

    it "can make redis" do
      Performant::Configuration.default.redis.should be_instance_of(Redis)
      c = Performant::Configuration.load src: File.expand_path( "../spec_10_0.yml", __FILE__ ), env: "test"
      c.redis.should be_instance_of(Redis)
      c = Performant::Configuration.new
      c.redis.should be_instance_of(Redis)
    end

  end # factory

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
