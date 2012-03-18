require "optparse"
require "ostruct"

module Performant
module Utilities
class Histogram

  def initialize( options = nil )
    @num = options && options[:buckets]
    @min = options && options[:min]
    @max = options && options[:max]
  end

  def process( numbers )
    num = @num || [ Math.sqrt( numbers.size ).floor, 3 ].max
    min = @min || numbers.min
    max = @max || numbers.max
    len = ( max - min ) / num

    bins = Array.new( num ) { 0 }
    numbers.each do |n|
      b = [ [ (n - min) / len, 0 ].max, num-1 ].min
      bins[b] += 1
    end
    bins
  end

end # Histogram
end # Utilities
end # Performant



