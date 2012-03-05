# -*- encoding: utf-8 -*-
require "fiber"

module Performant
class Monitor

  include Configuration::Configurable

  def kind( kind )
    Client.new( storage(kind), kind )
  end

  class Client

    attr :storage

    def initialize( storage, kind )
      @storage = storage
      @kind    = kind
    end

    # creates a job id and records it starting
    # returns the job id
    def start( time = Time.now )
      id = make_job_id( time )
      storage.record_start( id, time: time )
      # uninterruptedly {  }
      return id
    end

    def finish( id, time = Time.now )
      storage.record_finish( id, time: time )
      # uninterruptedly {  }
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
    protected
    #

    # returns false if we fail to execute the block before the timeout
    def uninterruptedly( timeout = 1, &block )
      expiration = Time.now + timeout
      begin
        return block.call
      rescue Storage::Interrupted => x
        return false if expiration < Time.now
        sleep(0.015625)
        retry
      end
    end # uninterruptedly

    def make_job_id( time = Time.now )
      @hostname ||= `hostname`.chomp
      "%s:%d:%s:%s:%f" % [ @hostname, Process.pid, Thread.current.object_id.to_s(36), Fiber.current.object_id.to_s(36), time.to_f ]
    end

  end # Client

  protected

  def storage( kind )
    configuration.storage.kind(kind)
  end

end # Monitor
end # Performant
