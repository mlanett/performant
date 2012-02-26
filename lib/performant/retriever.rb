# -*- encoding: utf-8 -*-
require "fiber"
require "redis"

module Performant
class Retriever

  include Configuration::Configurable

  attr :interval

  # param time is a point in a time interval. For instance given hourly intervals, 12:34:56 would select the 12:00..1:00 interval.
  def initialize( time )
    @interval = configuration.interval( time )
  end

  # The observation interval.
  def observation_interval
  end

  # The number of operations in the interval.
  def running_operations
  end

  # The total time during which operations resided in the system.
  def busy_time
  end

  # The total execution time of all operations.
  def weighted_time
  end

  # Throughput: number of operations in the observation interval divided by the length of the interval.
  def throughput
  end

  # Execution time: weighted time divided by the number of operations in the interval.
  def execution_time
  end

  # Concurrency: weighted time divided by the length of the interval.
  def concurrency
  end

  # Utilization: busy time divided by the length of the interval.
  def utilization
  end
  
end # Retriever
end # Performant
