# -*- encoding: utf-8 -*-
require "redis"

module Performant
class Storage

  include Configuration::Configurable

  def initialize
    @prefix = "performant"
  end

  # this is a transactional operation
  # @raises an exception if it fails
  def record( start_finish, time = Time.now )
    raise LogicError unless start_finish == :start || start_finish == :finish

    # Every time there is an arrival or completion, look at the counter of currently executing queries.
    # If it is greater than 0, add the time elapsed since the last arrival or completion.
    # Then increment the counter of currently executing queries if the current event is an arrival,
    # and decrement it if it’s a completion.
    # Finally, set the last-event timestamp to the current time.

    # ro > 0 ?  arrival?
    # true      true      operations still running, new operation starting
    # false     true      operation starting
    # true      false     operation finishing
    # false     false     ERROR

    with_watch( busy_time_f_key, work_time_f_key, last_tick_f_key ) do

      operations = redis.get( operations_key ).to_i
      if operations > 0 then
        last_tick_f = redis.get( last_tick_f_key ).to_f
        busy_time_f = redis.get( busy_time_f_key ).to_f
        work_time_f = redis.get( work_time_f_key ).to_f
        busy_time_f += ( time.to_f - last_tick_f )
        work_time_f += ( time.to_f - last_tick_f ) * operations
        result = redis.multi do |r|
          r.set( last_tick_f_key, time.to_f.to_s )
          r.set( busy_time_f_key, busy_time_f.to_f.to_s )
          r.set( work_time_f_key, work_time_f.to_f.to_s )
          start_finish == :start ? r.incr(operations_key) : r.decr(operations_key)
        end
        raise BusyTryAgain if ! result
        raise LogicError if result.size != 4
      else # operations == 0
        raise Corruption if start_finish != :start
        result = redis.multi do |r|
          r.set( last_tick_f_key, time.to_f.to_s )
          r.incr( operations_key )
        end
        raise BusyTryAgain if ! result
        raise LogicError if result.size != 2
      end

    end # watch

  end # record
  
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

  def busy_time_f_key
    @busy_time_f_key ||= "#{@prefix}:busy_time_f"
  end

  def work_time_f_key
    @work_time_f_key ||= "#{@prefix}:work_time_f"
  end

  def last_tick_f_key
    @last_tick_f_key ||= "#{@prefix}:last_tick_f"
  end

  def redis
    @redis ||= configuration.redis
  end

  class BusyTryAgain < StandardError; end
  class LogicError < Exception; end
  class Corruption < Exception; end

end # Storage
end # Performant
