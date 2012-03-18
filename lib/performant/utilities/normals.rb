=begin
  Returns random numbers with a normal distribution and standard deviation of 1.

  @see http://en.wikipedia.org/wiki/Box_Muller_transform
=end
module Performant
module Utilities
class Normals

  TWOPI = 2 * Math::PI
  
  def initialize
    @next = nil
    @rand = Random.new
  end

  def rand
    if @next then
      tmp = @next
      @next = nil
      return tmp
    else
      a = @rand.rand
      b = @rand.rand
      @next = Math.sqrt( -2 * Math.log(a) ) * Math.cos( TWOPI * b )
      return  Math.sqrt( -2 * Math.log(a) ) * Math.sin( TWOPI * b )
    end
  end

  def self.rand
    @@rand ||= new
    @@rand.rand
  end

end # Normals
end # Utilities
end # Performant
