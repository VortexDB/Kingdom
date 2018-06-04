# For delayed execution
class Timer
    # Start time
    @startTime : Time::Span = Time.monotonic

    # Block for calling at work
    @workBlock : Proc(Timer, Void)

    # Interval in seconds
    property interval : Time::Span
    
    # Is timer working
    getter isWorking = false

    # Work of timer
    private def work : Void
        return unless @isWorking

        @startTime = Time.monotonic
        delay(interval.total_seconds) do
            @workBlock.try &.call(self)
            work
        end
    end

    def initialize(@interval, &block : Timer -> _)
        @workBlock = block
        start
    end

    def initialize(seconds : Int32, &block : Timer -> _)
        @workBlock = block
        @interval = Time::Span.new(seconds: seconds, nanoseconds: 0)
        start
    end

    # Elapsed time after last execution
    def elapsed : Time::Span
        return Time.monotonic - @startTime
    end

    # Start timer
    def start
        @isWorking = true
        work
    end

    # Stop timer
    def stop
        @isWorking = false
    end

    # Restart timer
    def restart
        stop
        start
    end
end