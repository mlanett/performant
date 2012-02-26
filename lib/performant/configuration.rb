# -*- encoding: utf-8 -*-

module Performant
class Configuration

  def self.default
    Configuration.new
  end

  attr :interval_size
  attr :redis_options, true

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

  def redis
    redis_options ? Redis.connect( redis_options ) : Redis.connect
  end

  def storage
    configured Storage.new
  end

  def configured( it )
    it.configuration = self
    return it
  end

  module Configurable
    def self.included( c )
      c.class_eval do
        attr :configuration
        def configuration
          # auto-select default configuration if none present
          @configuration ||= Configuration.default
        end
        def configuration=( new_configuration )
          # allow configuration to be changed, *once*
          raise if @configuration || ! new_configuration
          @configuration = new_configuration
        end
      end
    end
  end # Configurable

end # Configuration
end # Performant
