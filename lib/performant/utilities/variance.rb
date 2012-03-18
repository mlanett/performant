#!/usr/bin/env ruby

def normal
  ( rand + rand + rand + rand + rand + rand + rand + rand ) / 8
end

class Summarizer

  def initialize
    @n = 0
    @s = 0
    @q = 0
  end

  def observe( x )
    @n += 1
    @s += x
    @q += x*x
  end

  def count
    @n
  end

  def mean
    @s / @n
  end

  def sum
    @s
  end

  def sum_squares
    @q
  end

  # @returns population variance
  def variance
    (sum_squares - sum * mean) / count
  end

  # @returns population standard deviation
  def standard_deviation
    Math.sqrt( variance )
  end

end
