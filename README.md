# Performant

Performant records four fundamental performance metrics:

- The observation interval under observation.
- The number of operations in the interval.
- The total time during which operations resided in the system — the “busy time.”
- The total execution time of all operations — the “working time.”

What is this good for? We can use these together with Little’s Law to derive these additional four long-term average metrics:

- Throughput: divide the number of queries in the observation interval by the length of the interval.
- Execution time: divide the working time by the number of queries in the interval.
- Concurrency: divide the working time by the length of the interval.
- Utilization: divide the busy time by the length of the interval.

How do we calculate this?

An approach which works is to have each job execute two actions:

- Start:
  - Increment the basic metrics.
  - Add itself to a running job set, with a timeout.
- Finish:
  - Check if it is still in the running job set.
  - If so,
    - Remove itself from the running job set.
    - Increment/decrement the basic metrics.

One problem with this approach is that start and finish actions must be balanced, but jobs can die.
So relying on the job to execute the finish action is not robust.
This is partly solved by the cleaner.

At the same time we need two processes to run continuously.

- Sampler:
    The sampler reads the basic metrics and calculates the long-term average metrics.
- Cleaner:
  - The cleaner checks for jobs which died without executing finish actions.
  - It removes them from the running job set and performs the finish action for them.

Special cases we have to support:

- Restarts:
  - A job starts, then dies.
  - Before the cleaner can clean up the job, it is restarted.
  - The job goes to register itself, but it already has “started”.
- Expiration:
  - A job registers with an expiration, but takes longer than that to execute.
  - Before it finished, the cleaner cleans up the job's entry.
  - The job goes to execute the finish actions, but it has already “finished”.

## Storage

Performant records high-volume data in Redis:

- Performant:Kinds              < Set < Kind > >
- Performant:{Kind}:Running     < SortedSet < Job ID scored by Expire time > >
- Performant:{Kind}:Busy Time   < int(ms) >
- Performant:{Kind}:Work Time   < int(ms) >
- Performant:{Kind}:Last Tick   < int(ms) >

Timestamps and durations are stored as integers in milliseconds.

The sampler captures the rollup values and writes them to Mongo:

- per second for at least the past 1 minute
- per minute for at least the past hour
- hourly for at least the past 3 days
- daily after that


See also:
http://www.mysqlperformanceblog.com/2011/04/27/the-four-fundamental-performance-metrics/
http://www.mysqlperformanceblog.com/2011/05/05/the-two-even-more-fundamental-performance-metrics/

Sampler daemon ideas:
The sampler may/will need a specific configuration file.
It will run from an installed gem.
e.g. sampler -c ~/foo/bar/config.yml -e production COMMAND
Pid and Log file location may be set in the config file.
It might be better if the configuration file is self-executing, e.g.
  ~/foo/bar/sampler -e production COMMAND
It will need to support bundler, e.g.
  ( cd ~/foo/bar; bundle exec sampler -e production COMMAND )

## Out-of-order event arrival
What if these two events arrive out of order? e.g. the A event arrives after the B event, even though it occurred first.
Our strategy for handling these is to adjust the timestamp on the out-of-order event.
This results in very small inaccuracies which are generally fine, and should cancel out.

- A Start, B Start:   Ok; A's start moved to after B's start; some work time not recorded for A.
- A Start, B Finish:  Same effect as above.
- A Finish, B Start:  Ok; A's finish moved to after B's start; some extra work time recorded for A.
- A Finish, B Finish: Same effect as above.