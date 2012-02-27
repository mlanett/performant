# -*- encoding: utf-8 -*-
require "fiber"

module Performant
class Monitor

  include Configuration::Configurable

  # creates a job id and records it starting
  # returns the job id
  def start( time = Time.now )
    id = make_job_id( time )
    record_endpoint( :start, time )
    return id
  end

  def finish( job_id, time = Time.now )
    record_endpoint( :finish, time )
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

  def record_endpoint( sof, time = Time.now )
    storage.with_retries { storage.record_endpoint( sof, time ) }
  end # record_endpoint

  private

  def make_job_id( time = Time.now )
    "%s:%d:%s:%s:%f" % [ `hostname`.chomp, Process.pid, Thread.current.object_id, Fiber.current.object_id, time.to_f ]
  end

end # Monitor
end # Performant
