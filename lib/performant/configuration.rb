# -*- encoding: utf-8 -*-
require "erb"
require "redis"
require "yaml"

module Performant
class Configuration

  attr :interval_size
  attr :redis_options, true

  def initialize( options = {} )
    options  = Hash[ options.map { |k,v| [ k.to_sym, v ] } ].freeze # poor man's symbolize keys
    @interval_size = options[:interval_size] || 60
    @redis_options = options[:redis] || { url: "redis://127.0.0.1:6379/0" }
  end

  # @returns a range containing the start and finish endpoints; this is a non-inclusive interval
  # e.g. you'll get something like 1:00 ... 2:00, not 1:00 .. 1:59:59
  def interval( time = Time.now )
    # Ruby doesn't incorporate leap second support, so this approach works fine [2012 Feb 26 mlanett 1.9.2]
    start  = Time.at( time.to_i - time.to_i % interval_size )
    finish = start + interval_size
    (start ... finish)
  end

  # @returns a list containing the start endpoints for the given range; this is inclusive.
  def buckets( start, finish )
    # 3:27
    # 7:43
    # 3 4 5 6 7
    result = []
    start  = interval(start).first
    finish = Time.at finish.to_i
    while start <= finish
      result << start
      start  += interval_size
    end
    result
  end

  def redis
    redis_options ? Redis.connect( redis_options ) : Redis.connect
  end

  # ----------------------------------------------------------------------------
  # Factory methods
  # ----------------------------------------------------------------------------

  def storage
    configured Storage.new
  end

  def monitor
    configured Monitor.new
  end

  # ----------------------------------------------------------------------------
  # Default Configuration
  # ----------------------------------------------------------------------------

  # @returns the default Configuration
  def self.default
    @default || load
  end

  # Sets the default Configuration from a YAML+ERB file.
  # The file may contain a "default" block which will be merged into the environment blocks.
  # @returns the default Configuration
  def self.load( options = {} )
    src = options[:src] || "#{ENV['RACK_ROOT']}/config/performant.yml"
    env = options[:env] || ENV["RACK_ENV"]
    yml = YAML.load( ERB.new( IO.read( src ) ).result )
    set( ( yml["default"] || {} ).merge( yml[env] || {} ) )
  end

  # Sets the default Configuration from a set of options.
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

  # ----------------------------------------------------------------------------
  protected
  # ----------------------------------------------------------------------------

  def configured( thing )
    thing.configuration = self
    return thing
  end

end # Configuration
end # Performant
