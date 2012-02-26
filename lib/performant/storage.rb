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
  def record( start_finish, now = Time.now )
    raise unless start_finish == :start || start_finish == :finish

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

    with_watch( busy_time_key, work_time_key, last_tick_key ) do

      operations = redis.get( operations_key ).to_i
      if operations > 0 then
        last_tick = redis.get( last_tick_key ).to_f
        busy_time = redis.get( busy_time_key ).to_f
        work_time = redis.get( work_time_key ).to_f
        busy_time += ( now.to_f - last_tick )
        work_time += ( now.to_f - last_tick ) * operations
        result = redis.multi do |r|
          r.set( last_tick_key, now.to_f.to_s )
          r.set( busy_time_key, busy_time )
          r.set( work_time_key, work_time )
          start_finish == :start ? r.incr(operations_key) : r.decr(operations_key)
        end
        raise if ! ( result && result.size == 4 )
      else # operations == 0
        raise if start_finish != :start
        result = redis.multi do |r|
          r.set( last_tick_key, now.to_f.to_s )
          r.incr( operations_key )
        end
        raise if ! ( result && result.size == 2 )
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

  def busy_time_key
    @busy_time_key ||= "#{@prefix}:busy_time"
  end

  def work_time_key
    @work_time_key ||= "#{@prefix}:work_time"
  end

  def last_tick_key
    @last_tick_key ||= "#{@prefix}:last_tick"
  end

  def redis
    @redis ||= configuration.redis
  end

end # Storage
end # Performant
