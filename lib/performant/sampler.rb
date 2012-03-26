# -*- encoding: utf-8 -*-
require "fiber"

module Performant
class Sampler

  include Configuration::Configurable

  attr :jobs

  def initialize( jobs )
    @jobs   = jobs.freeze
    @stores = jobs.inject({}) { |a,job| a[job] = Performant.storage(job); a }
  end

  def run
    loop_until_false do
      puts Time.now
      jobs.each do |job|
        x = sample(job)
        puts x.inspect
      end
      true
    end
  end

  def sample!( job, time = Time.now )
    storage = store(job)
    last    = storage.get_sample
    current = storage.robustly { storage.tick!(time) }
    diff    = diff( current, last )
    storage.save_sample( current )
    diff.merge( job: job )
  end

  private

  def loop_until_false( &block )
    next_time = next_sample
    loop do
      wait_until( next_sample )
      next_time = next_sample
      x = block.call
      break if ! x
    end
  end

  # @returns next minute, or so
  def next_sample
    now = Time.now
    Time.at( now.to_i + configuration.interval_size - now.to_i % configuration.interval_size )
  end

  # sleeps until next time; tries to wake up *right* after the given time.
  def wait_until( time )
    while (d = time - Time.now) > 0 do
      sleep( d * 0.8 )
    end
  end

  def diff( b, a )
    jobs   = (b[:jobs] || 0).to_i
    busy   = (b[:busy] || 0.0) - (a[:busy] || 0.0)
    work   = (b[:work] || 0.0) - (a[:work] || 0.0)
    starts = ((b[:starts] || 0) - (a[:starts] || 0)).to_i
    return { jobs: jobs, busy: busy, work: work, starts: starts }
  end

  def store( s )
    @stores[s] or raise "No Tracking #{s}"
  end

end # Sampler
end # Performant
