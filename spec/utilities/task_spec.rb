# -*- encoding: utf-8 -*-
require "helper"
require "performant/utilities/task"

class A < Performant::Utilities::Task
  option "p", "processes", default: 2
end

class B < Performant::Utilities::Task
  option "p", "processes", default: 3
end

describe Performant::Utilities::Task do

  it "should allow multiple subclasses" do
    A.new( ["-p", "1"] ).processes.should eq(1)
    B.new( [] ).processes.should eq(3)
  end

end
