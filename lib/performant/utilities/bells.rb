=begin
  Returns random numbers with an approximated normal distribution limited to the range 0..1
=end
module Performant
module Utilities
class Bells

  def initialize
    @rand = Random.new
  end

  def rand
    ( @rand.rand + @rand.rand + @rand.rand ) / 3
  end

end # Bells
end # Utilities
end # Performant
