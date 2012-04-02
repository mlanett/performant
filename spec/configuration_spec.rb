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

    it "can merge defaults deeply" do
      c = Performant::Configuration.load src: File.expand_path( "../spec_nested.yml", __FILE__ ), env: "test"
      #c.mongos["hosts"].should_not be_nil
      #c.mongos["database"].should_not be_nil
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

  describe "utilities" do
    it "can do a deep freeze" do
      x = { a: [ { b: "b" }, "c" ], d: "d" }
      y = Performant::Configuration.deep_freeze(x)
      x.should eq(y)
      expect { y[:a] = nil }.to raise_exception
      expect { y[:a][0] = nil }.to raise_exception
      expect { y[:a][0][:b] = nil }.to raise_exception
      expect { y[:e] = 1 }.to raise_exception
    end
    it "can symbolize deeply" do
      x = { "a" => [ { "b" => "b" }, "c" ], "d" => "d" }
      y = Performant::Configuration.deep_symbolize(x)
      puts y.inspect
      y[:a][0][:b].should_not be_nil
    end
  end # utilities

end
