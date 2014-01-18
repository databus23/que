# Similar to the standard library's Queue class in terms of synchronizing
# access, but keeps jobs in the order we want to work them. Assumes there's
# many threads competing to retrieve jobs.

module Que
  class JobQueue
    def initialize
      @array = []
      @mutex = Mutex.new
      @cv    = ConditionVariable.new
    end

    def push(*jobs)
      jobs.flatten!

      @mutex.synchronize do
        # At some point, for large queue sizes and small numbers of jobs to
        # insert, it may be worth investigating an insertion by binary search.
        @array.push(*jobs).sort_by! { |job| job.values_at(:priority, :run_at, :job_id) }
        @cv.signal
      end
    end

    # Implementation borrowed from the rubysl-thread gem.
    def shift
      loop do
        @mutex.synchronize do
          if @array.empty?
            @cv.wait(@mutex)
          else
            item = @array.shift
            @cv.signal
            return item
          end
        end
      end
    end

    def to_a
      @array.dup
    end
  end
end