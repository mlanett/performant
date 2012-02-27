# -*- encoding: utf-8 -*-
require "yaml"
require "erb"

module Performant
class Configuration

  attr :interval_size
  attr :redis_options, true

  def initialize( options = {} )
    @interval_size = options[:interval_size] || 60
    @redis_options = options[:redis] || { url: "redis://127.0.0.1:6379/0" }
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

  # ----------------------------------------------------------------------------
  # Default Configuration
  # ----------------------------------------------------------------------------

  # @returns the default Configuration
  def self.default
    @default || load( "#{ENV['RACK_ROOT']}/config/performant.yml", ENV["RACK_ENV"] )
  end

  # @returns the default Configuration
  def self.load( src, env )
    set( YAML.load( ERB.new( IO.read( src ) ).result ) [ env ] )
  end

  # @returns the default Configuration
  def self.set( options )
    @default = Configuration.new( options )
  end

  # ----------------------------------------------------------------------------
  # Metaprogramming for client classes
  # ----------------------------------------------------------------------------

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
          raise Immutable if @configuration || ! new_configuration
          @configuration = new_configuration
        end
      end
    end
  end # Configurable

  class Immutable < Exception; end

end # Configuration
end # Performant
