# -*- encoding: utf-8 -*-
require "fiber"

module Performant
class Monitor

  include Configuration::Configurable

  def job( job )
    Client.new( storage(job), job )
  end

  class Client

    attr :storage

    def initialize( storage, job )
      @storage = storage
      @job    = job
    end

    def track( &block )
      id = start
      begin
        yield
      ensure
        finish( id )
      end
    end

    # creates a job id and records it starting
    # returns the job id
    def start( time = Time.now )
      id = make_job_id( time )
      storage.uninterruptedly { storage.record_start( id, time: time ) }
      return id
    end

    def finish( id, time = Time.now )
      storage.uninterruptedly { storage.record_finish( id, time: time ) }
    end

    #
    protected
    #

    def make_job_id( time = Time.now )
      @hostname ||= `hostname`.chomp
      "%s@%s:%d:%s:%s:%f" % [ @job, @hostname, Process.pid, Thread.current.object_id.to_s(36), Fiber.current.object_id.to_s(36), time.to_f ]
    end

  end # Client

  protected

  def storage( job )
    configuration.storage.job(job)
  end

end # Monitor
end # Performant
