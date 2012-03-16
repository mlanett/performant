# -*- encoding: utf-8 -*-

=begin

  Cleaner is a job which runs periodically and cleans up dead jobs.
  It writes their time to the log system.

=end

module Performant
class Cleaner

  include Configuration::Configurable

  attr :jobs

  def initialize( jobs )
    @jobs = jobs
  end

  def expire_any_jobs
    n = 0
    jobs.each do |job|
      n += storage(job).expire_jobs
    end
    n
  end

  def run
    slacker do
      n = expire_any_jobs
      n > 0
    end
  end

  # ----------------------------------------------------------------------------
  protected
  # ----------------------------------------------------------------------------

  # run block until it throws :stop
  # block should return true (acted) or false (inaction)
  # sleeps in between calls which return false
  # sleep period will increase with repeated inaction
  # @param min sleep defaults to 1 second
  # @param max sleep defaults to 60 seconds
  def slacker( options = nil, &block )
    min = options && options[:min] || 1
    max = options && options[:min] || 60
    nap = min
    until_stop do

      acted = block.call

      if acted then
        # reset nap time, but do not nap
        nap = min
      else
        # nap, then increase nap time in case next time also has no action
        sleep(nap)
        nap = [ nap * 2, max ].min
      end

    end
  end

  # throw :stop to exit.
  def until_stop( &block )
    catch :stop do
      loop do
        block.call
      end
    end
  end

  def storage( job )
    @storage ||= configuration.storage
    @storage.job( job )
  end

end # Cleaner
end # Performant
