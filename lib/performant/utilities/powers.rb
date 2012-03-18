class Powers

  # min and max are both inclusive
  # n is the distribution power: the higher, the more biased
  def initialize( min, max, n )
    @min = min
    @max = max + 1
    @pow = n + 1
    @mrp = @min ** @pow
    @run = @max ** @pow - @mrp
    @sub = 1.0 / @pow
  end

  def rand
    pl = ( @run * rand + @mrp ) ** @sub
    ( @max - 1 - pl.to_i ) + @min
  end

end
