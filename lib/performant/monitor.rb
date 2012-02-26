# -*- encoding: utf-8 -*-

require "fiber"

module Performant
class Monitor

  include Configuration::Configurable

  # creates a job id and records it starting
  # returns the job id
  def start( now = Time.now )
    id = make_job_id( now )
    record( :start, now )
    return id
  end

  def finish( job_id, now = Time.now )
    record( :finish, now )
  end

  def run( &block )
    id = start
    begin
      yield
    ensure
      finish( id ) if id
    end
  end

  #
  # event processing
  #

  def record( start_or_finish, now = Time.now )
    timeout = Time.now + 10

    begin
      storage.record( start_or_finish, now )
      return true

    rescue Storage::BusyTryAgain => x
      return false if timeout < Time.now
      sleep(rand) # XXX not fiber-friendly!
      retry

    rescue => x
      # XXX do something

    end

  end # record

  private

  def make_job_id( time = Time.now )
    "%s:%d:%s:%s:%f" % [ `hostname`.chomp, Process.pid, Thread.current.object_id, Fiber.current.object_id, time.to_f ]
  end

end # Monitor
end # Performant