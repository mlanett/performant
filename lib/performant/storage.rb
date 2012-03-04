# -*- encoding: utf-8 -*-
require "redis"

module Performant
class Storage

  include Configuration::Configurable

  def initialize
    @prefix = "performant"
  end

  # returns false if we fail to execute the block before the timeout
  def with_retries( timeout = 10, &block )
    expiration = Time.now + timeout

    begin
      return block.call

    rescue BusyTryAgain => x
      return false if expiration < Time.now
      sleep(rand) # XXX not fiber-friendly!
      retry

    end
  end

  protected

  def with_watch( *args, &block )
    # Note: watch() gets cleared by a multi() but it's safe to call unwatch() anyway.
    redis.watch( *args )
    begin
      block.call
    ensure
      redis.unwatch
    end
  end

  def operations_key
    @operations ||= "#{@prefix}:operations"
  end

  def busy_time_key
    @busy_time_key ||= "#{@prefix}:busy_time_f"
  end

  def work_time_key
    @work_time_key ||= "#{@prefix}:work_time_f"
  end

  def last_tick_key
    @last_tick_key ||= "#{@prefix}:last_tick_f"
  end

  def redis
    @redis ||= configuration.redis
  end

  class BusyTryAgain < StandardError; end
  class LogicError < Exception; end
  class Corruption < Exception; end

end # Storage
end # Performant
