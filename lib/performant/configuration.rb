module Performant
class Configuration

  attr :interval_size

  def initialize( options = {} )
    @interval_size = options[:interval_size] || 60
  end

  # @returns a range containing the start and finish endpoints; this is a non-inclusive interval
  # e.g. you'll get something like 1:00 ... 2:00, not 1:00 .. 1:59:59
  def interval( time = Time.now )
    start  = Time.at( time.to_i - time.to_i % interval_size )
    finish = start + interval_size
    (start ... finish)
  end

end
end # Performant
