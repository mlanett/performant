# -*- encoding: utf-8 -*-
require "fiber"

module Performant
class Monitor

  include Configuration::Configurable

  # creates a job id and records it starting
  # returns the job id
  def start( time = Time.now )
    id = make_job_id( time )
    storage.record_start( id, time: time )
    return id
  end

  def finish( id, time = Time.now )
    storage.record_finish( id, time: time )
  end

  def track( kind = "test", timeout = 60, &block )
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

  def storage
    @storage ||= configuration.storage
  end

  private

  def make_job_id( time = Time.now )
    @hostname ||= `hostname`.chomp
    "%s:%d:%s:%s:%f" % [ @hostname, Process.pid, Thread.current.object_id.to_s(36), Fiber.current.object_id.to_s(36), time.to_f ]
  end

end # Monitor
end # Performant
