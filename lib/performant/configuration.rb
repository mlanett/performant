# -*- encoding: utf-8 -*-
require "erb"
require "redis"
require "yaml"

module Performant
class Configuration

  DEFAULT_CONFIG = {
    environment: "development",
    interval_size: 60,
    redis: { url: "redis://127.0.0.1:6379/0" },
    mongo: { hosts: [ "localhost:27017" ], database: "test", safe: false },
    rollups: [ "hour", "day", "month" ]
  }

  NAMED_ROLLUPS   = { "minute" => 60, "hour" => 3_600, "day" => 86_400, "week" => 604_800, "month" => 2_592_000 }

  attr :options
  attr :environment
  attr :interval_size
  attr :redis_options, true

  def initialize( options = {} )
    @options          = self.class.deep_freeze( self.class.deep_merge( DEFAULT_CONFIG, self.class.deep_symbolize( options ) ) )
    @environment      = @options[:environment]
    @interval_size    = @options[:interval_size]
    @redis_options    = @options[:redis]
    #mongos           = @options[:mongo]
    #rollup_intervals = valid_rollup_intervals( @options[:rollups] )
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

  def monitor
    configured Monitor.new
  end

  def sampler( jobs )
    configured Sampler.new( jobs )
  end

  def storage
    configured Storage.new
  end

  # ----------------------------------------------------------------------------
  # Default Configuration
  # ----------------------------------------------------------------------------

  def default!
    @@default = self
  end

  # @returns the default Configuration
  def self.default
    @@default ||= load
  end

  # Loads a Configuration from a YAML+ERB file.
  # The file may contain a "default" block which will be merged into the environment blocks.
  # @returns a Configuration
  def self.load( options = {} )
    src = options[:src] || "#{ENV['RACK_ROOT']}/config/performant.yml"
    env = options[:env] || ENV["RACK_ENV"] || "development"
    yml = YAML.load( ERB.new( IO.read( src ) ).result )
    uni = { environment: env }.merge( deep_merge( ( yml["default"] || {} ), ( yml[env] || {} ) ) )
    Configuration.new( uni )
  end

  def self.load!( options )
    load( options ).default!
  end

  def self.set!( options )
    new( options ).default!
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

  def self.deep_freeze( it )
    case it
    when nil
      nil
    when Hash
      Hash[ it.map { |kv| [ kv[0].freeze, deep_freeze(kv[1]) ] } ].freeze
    when Array
      it.map { |i| deep_freeze(i) }.freeze
    when Object
      it.freeze
    end
  end

  # merges hashes recursively
  def self.deep_merge( defaults, additional )
    m = {}
    defaults.merge( additional )  do | key, default_val, additional_val |
      m[key] = ( Hash === default_val && Hash === additional_val ) ? deep_merge( default_val, additional_val ) : additional_val
    end
  end

  def self.deep_symbolize( h )
    case h
    when Hash
      s = {}
      h.each do |k,v|
        s[k.to_s.to_sym] = deep_symbolize(v)
      end
      s
    when Array
      h.map { |i| deep_symbolize(i) }
    else
      h
    end
  end

end # Configuration
end # Performant
