# -*- encoding: utf-8 -*-
require "redis"

module Performant
class Storage

  include Configuration::Configurable

  def job( job )
    Client.new( redis, job )
  end

  class Client

    attr :redis

    def initialize( redis, job )
      @redis  = redis
      @prefix = "performant:#{job}"
    end

    def sample
      # this isn't a transaction, just a bulk read operation
      result = redis.multi do |r|
        r.zcard( jobs_key )
        r.get( busy_key )
        r.get( work_key )
        r.get( start_key )
      end

      return { jobs: result[0], busy: (result[1].to_i / 1000.0), work: (result[2].to_i / 1000.0), starts: result[3].to_i }
    end

    # Updates the busy and work values
    def tick!( time = Time.now )
      time_ms = to_ms( time )

      with_watch( *all_keys ) do

        operations = redis.zcard( jobs_key )
        last_ms    = redis.get( last_key ).to_i
        time_ms,diff_ms = reorder( time_ms, last_ms )

        result = if operations > 0 then
          # Increment time consumed by current jobs.
          # And fetch the cumulative work values.

          multi( "busy tick", 6 ) do |r|
            r.incrby( busy_key, diff_ms )
            r.incrby( work_key, diff_ms * operations )
            r.set( last_key, time_ms )
            r.get( busy_key )
            r.get( work_key )
            r.get( start_key )
          end.slice(3,3)

        else

          # Nothing is running, just update the timestamp.
          # And fetch the cumulative work values.
          multi( "quiet tick", 4 ) do |r|
            r.set( last_key, time_ms )
            r.get( busy_key )
            r.get( work_key )
            r.get( start_key )
          end.slice(1,3)

        end # result

        return { jobs: operations, busy: (result[0].to_i / 1000.0), work: (result[1].to_i / 1000.0), starts: result[2].to_i }
      end # watch
    end # tick!

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
      expire_ms = to_ms( time + timeout ) # Will be correct even if time is adjusted by reorder

      # Watch all keys we query and then execute changes in a multi/transaction, so we never make any change using stale data.
      with_watch( *all_keys ) do

        operations = redis.zcard( jobs_key )
        last_ms    = redis.get( last_key ).to_i
        has_job    = ! redis.zrank( jobs_key, id ).nil?
        time_ms,diff_ms = reorder( time_ms, last_ms )

        if has_job then
          # This job is already running?! Not expected. But could happen.
          # Reset expiration.
          # No need to increment work counters since operation count hasn't changed.

          multi( "re-start #{id}", 1 ) do |r|
            r.zadd( jobs_key, expire_ms, id )
          end

        elsif operations > 0 then
          # Some jobs are already running
          # Increment time consumed by current jobs.
          # Add this job.

          multi( "start more #{id}", 5 ) do |r|
            r.incrby( busy_key, diff_ms )
            r.incrby( work_key, diff_ms * operations )
            r.set( last_key, time_ms )
            r.zadd( jobs_key, expire_ms, id )
            r.incrby( start_key, 1 )
          end

        else
          # No jobs are running.
          # Add this job.

          multi( "start #{id}", 3 ) do |r|
            r.set( last_key, time_ms )
            r.zadd( jobs_key, expire_ms, id )
            r.incrby( start_key, 1 )
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
        has_job    = ! redis.zrank( jobs_key, id ).nil?
        raise NoSuchJob.new(id) if ! has_job
        time_ms,diff_ms = reorder( time_ms, last_ms )


        multi( "finish #{id}", 4) do |r|
          r.incrby( busy_key, diff_ms )
          r.incrby( work_key, diff_ms * operations )
          r.set( last_key, time_ms )
          r.zrem( jobs_key, id )
        end

      end # watch
      self
    end # record_finish

    def nuke!
      redis.del *all_keys
    end

    # returns a list of expired jobs
    # is limited to 10
    def expired_jobs( options = nil )
      time    = options && options[:time] || Time.now
      time_ms = to_ms( time )
      operations = redis.zrangebyscore( jobs_key, "-inf", time_ms, limit: [0,10] )
    end

    def expire_jobs( options = nil )
      count   = 0
      time    = options && options[:time] || Time.now
      time_ms = to_ms( time )
      loop do
        operations = expired_jobs( time: time )
        break if operations.size == 0
        operations.each do |id|
          record_finish( id, time: time )
          count += 1
        end
      end
      count
    end

    # returns false if we fail to execute the block before the timeout
    def robustly( timeout = 1, &block )
      expiration = Time.now + timeout
      begin
        return block.call
      rescue Interrupted => x
        return false if expiration < Time.now
        sleep(0.015625)
        retry
      end
    end # robustly

    def get_sample
      it = redis.hgetall( "#{@prefix}:sample" )
      return {
        jobs: it["jobs"].to_i || 0,
        busy: it["busy"].to_f || 0,
        work: it["work"].to_f || 0,
        starts: it["starts"].to_i || 0
      }
    end

    def save_sample( sample )
      sample = { jobs: 0, busy: 0.0, work: 0.0, starts: 0 }.merge( sample )
      redis.mapped_hmset( "#{@prefix}:sample", sample )
      self
    end

    protected

    # We calculate the difference between two times
    # @param now is assumed to be approximately Time.now
    # @param last is some pre-recorded timestamp, which should be in the past.
    # In some cases, due to out-of-order executions, last may be *after* time.
    # We can't process negative durations, so we:
    # => adjust the duration to be 0.
    # => return the last time as the new "now" time.
    # This has the effect of moving the out-of-order timepoint ahead slightly, which is generally Ok.
    # @raises OutOfOrder if adjustment is too large (negative)
    def reorder( now, last, limit = -1000 )
      diff = now - last
      return [ now, diff ] if diff >= 0
      raise OutOfOrder.new((-diff).to_s) if diff < limit
      return [ last, 0 ]
    end

    def to_ms( time )
      (1000 * time.to_r).to_i
    end

    def multi( what, count, &block )
      result = redis.multi(&block)
      raise Interrupted if ! result
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

    def start_key
      @start_key ||= "#{@prefix}:starts"
    end

    def all_keys
      [ jobs_key, busy_key, work_key, last_key ]
    end

  end # Client

  protected

  def redis
    @redis ||= configuration.redis
  end

  class Interrupted < StandardError; end
  class OutOfOrder < StandardError; end
  class NoSuchJob < Exception; end
  class UnexpectedResults < Exception; end

end # Storage
end # Performant
