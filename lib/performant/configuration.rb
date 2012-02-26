module Performant
class Configuration

  def self.default
    Configuration.new
  end

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

  module Configurable
    def self.included( it )
      it.send( :attr, :configuration )
      it.define_method( :configuration ) do
        # auto-select default configuration if none present
        @configuration ||= Configuration.default
      end
      it.define_method( :configuration= ) do |new_configuration|
        # allow configuration to be changed, *once*
        raise if @configuration || ! new_configuration
        @configuration = new_configuration
      end
    end
  end

end
end # Performant
