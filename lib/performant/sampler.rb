# -*- encoding: utf-8 -*-
require "fiber"

module Performant
class Sampler

  include Configuration::Configurable

  def sample( interval )
    # read current totals from redis
    # calculate deltas since last time
    # write them into the interval
    # roll up the interval as necessary
  end

  def next_sample
    # next minute
    now = Time.now
    Time.at( now.to_i + configuration.interval_size - now.to_i % configuration.interval_size )
  end

  def loop_until_false( &block )
    next_time = next_sample
    loop do
      wait_until( next_sample )
      next_time = next_sample
      x = block.call
      break if ! x
    end
  end

  # sleeps until next time; tries to wake up *right* after the given time.
  def wait_until( time )
    while (d = time - Time.now) > 0 do
      sleep( d / 2.0 )
    end
  end

  def diff( sample2, sample1 )
    jobs = (sample2[:jobs] || 0)
    busy = (sample2[:busy] || 0) - (sample1[:busy] || 0)
    work = (sample2[:work] || 0) - (sample1[:work] || 0)
    return { jobs: jobs, busy: busy, work: work }
  end

end # Sampler
end # Performant