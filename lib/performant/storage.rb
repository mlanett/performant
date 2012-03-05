# -*- encoding: utf-8 -*-
require "redis"

module Performant
class Storage

  include Configuration::Configurable

  def client( kind = "test" )
    Client.new( redis, kind )
  end

  class Client

    attr :redis

    def initialize( redis, kind )
      @redis  = redis
      @prefix = "performant:#{kind}"
    end

    def sample
      result = redis.multi do |r|
        r.zcard( jobs_key )
        r.get( busy_key )
        r.get( work_key )
      end

      return { jobs: result[0], busy: (result[1].to_i / 1000.0), work: (result[2].to_i / 1000.0) }
    end

    # Updates the busy and work values
    def sample!( time = Time.now )
      time_ms = to_ms( time )

      with_watch( *all_keys ) do

        operations = redis.zcard( jobs_key )
        last_ms    = redis.get( last_key ).to_i
        diff_ms    = delta( time_ms, last_ms )

        result = if operations > 0 then
          # Increment time consumed by current jobs.
          # And fetch the cumulative work values.

          multi(5) do |r|
            r.incrby( busy_key, diff_ms )
            r.incrby( work_key, diff_ms * operations )
            r.set( last_key, time_ms )
            r.get( busy_key )
            r.get( work_key )
          end.slice(3,2)

        else

          # Nothing is running, just update the timestamp.
          # And fetch the cumulative work values.
          multi(3) do |r|
            r.set( last_key, time_ms )
            r.get( busy_key )
            r.get( work_key )
          end.slice(1,2)

        end # result

        return { jobs: operations, busy: (result[0].to_i / 1000.0), work: (result[1].to_i / 1000.0) }
      end # watch
    end # sample!

    # This is a transactional operation - it may fail if it co-executes with another transaction.
    # If the given job is already running, the timeout is extended.
    # @option timeout in seconds defaults to 60
    # @option time should be now, but may be given for testing purposes
    # @raises an exception if this job is already running
    # @raises an exception if it fails
    def record_start( id, options = nil )
      timeout   = options && options[:timeout] || 60
      time      = options && options[:time]    || Time.now
      time_ms   = to_ms( time )
      expire_ms = to_ms( time + timeout ) # will not be exactly correct if time is adjusted for delta

      # Watch all keys we query and then execute changes in a multi/transaction, so we never make any change using stale data.
      with_watch( *all_keys ) do

        operations = redis.zcard( jobs_key )
        last_ms    = redis.get( last_key ).to_i
        has_job    = ! redis.zrank( jobs_key, id ).nil?
        time_ms,diff_ms = delta( time_ms, last_ms )

        if has_job then
          # This job is already running?! Not expected. But could happen.
          # Reset expiration.
          # No need to increment work counters since operation count hasn't changed.

          multi(1) do |r|
            r.zadd( jobs_key, expire_ms, id )
          end

        elsif operations > 0 then
          # Some jobs are already running
          # Increment time consumed by current jobs.
          # Add this job.

          multi(4) do |r|
            r.incrby( busy_key, diff_ms )
            r.incrby( work_key, diff_ms * operations )
            r.set( last_key, time_ms )
            r.zadd( jobs_key, expire_ms, id )
          end

        else
          # No jobs are running.
          # Add this job.

          multi(2) do |r|
            r.set( last_key, time_ms )
            r.zadd( jobs_key, expire_ms, id )
          end

        end
      end # watch
      self
    end # record_start

    def record_finish( id, options = nil )
      time     = options && options[:time] || Time.now
      time_ms  = to_ms( time )

      with_watch( *all_keys ) do

        operations = redis.zcard( jobs_key )
        last_ms    = redis.get( last_key ).to_i
        diff_ms    = delta( time_ms, last_ms )
        has_job    = ! redis.zrank( jobs_key, id ).nil?

        raise NoSuchJob.new(id) if ! has_job

        multi(4) do |r|
          r.incrby( busy_key, diff_ms )
          r.incrby( work_key, diff_ms * operations )
          r.set( last_key, time_ms )
          r.zrem( jobs_key, id )
        end

      end # watch
      self
    end # record_finish

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

    # We calculate the difference between two times
    # Negative durations are not permitted, so we accept some slop, returning last time as now time
    # @returns 0 if the duration is small
    # @raises OutOfOrder.new(diff_ms.to_s) if diff_ms < 0
    def delta( now, last, limit = -1000 )
      diff = now - last
      return [ now, diff ] if diff >= 0
      raise OutOfOrder.new((-diff).to_s) if diff < limit
      return [ last, 0 ]
    end

    def to_ms( time )
      (time.to_f * 1000).to_i
    end

    def multi( count, &block )
      result = redis.multi(&block)
      raise BusyTryAgain if ! result
      raise UnexpectedResults.new(result.size.to_s) if result.size != count
      result
    end

    def with_watch( *args, &block )
      # Note: watch() gets cleared by a multi() but it's safe to call unwatch() anyway.
      redis.watch( *args )
      begin
        block.call
      ensure
        redis.unwatch
      end
    end

    def jobs_key
      @jobs_key ||= "#{@prefix}:jobs"
    end

    def busy_key
      @busy_key ||= "#{@prefix}:busy"
    end

    def work_key
      @work_key ||= "#{@prefix}:work"
    end

    def last_key
      @last_key ||= "#{@prefix}:last"
    end

    def all_keys
      [ jobs_key, busy_key, work_key, last_key ]
    end

  end # Client

  protected

  def redis
    @redis ||= configuration.redis
  end

  class BusyTryAgain < StandardError; end
  class OutOfOrder < StandardError; end
  class NoSuchJob < Exception; end
  class UnexpectedResults < Exception; end

end # Storage
end # Performant
