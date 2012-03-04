# -*- encoding: utf-8 -*-
require "helper"

describe Performant::Storage, redis: true, redis_configuration: true do

  subject { Performant.storage }

  it "should record one operation"

  it "should record sequential operations"

  it "should record multiple overlapping operations"

  it "prohibits recording endpoints out of order"

end
