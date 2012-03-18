# -*- encoding: utf-8 -*-
require "helper"
require "performant/utilities/normals"

describe Performant::Utilities::Normals do

  it "can generate instance normals" do
    subject.rand.should be_an_instance_of(Float)
    subject.rand.should be_an_instance_of(Float)
    subject.rand.should be_an_instance_of(Float)
  end

  it "can generate global normals" do
    Performant::Utilities::Normals.rand.should be_an_instance_of(Float)
    Performant::Utilities::Normals.rand.should be_an_instance_of(Float)
    Performant::Utilities::Normals.rand.should be_an_instance_of(Float)
  end

end
