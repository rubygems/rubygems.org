module NewRelic::Agent
  
  # A worker loop executes a set of registered tasks on a single thread.  
  # A task is a proc or block with a specified call period in seconds.  
  class WorkerLoop
    
    attr_reader :log
    attr_reader :pid
    
    def initialize(log = Logger.new(STDERR))
      @tasks = []
      @log = log
      @should_run = true
      @pid = $$
    end
    
    # Run infinitely, calling the registered tasks at their specified
    # call periods.  The caller is responsible for creating the thread
    # that runs this worker loop
    def run
      while keep_running do
        run_next_task
      end
    end
    
    def keep_running
      @should_run && (@pid == $$)
    end
    
    def stop
      @should_run = false
    end
    
    MIN_CALL_PERIOD = 0.1
    
    # add a task to the worker loop.  The task will be called approximately once
    # every call_period seconds.  The task is passed as a block
    def add_task(call_period, desc="", &task_proc)
      if call_period < MIN_CALL_PERIOD
        raise ArgumentError, "Invalid Call Period (must be > #{MIN_CALL_PERIOD}): #{call_period}" 
      end
      @tasks << LoopTask.new(call_period, desc, &task_proc)
    end
    
    private 
    def next_task
      @tasks.inject do |soonest, task|
       (task.next_invocation_time < soonest.next_invocation_time) ? task : soonest
      end
    end
    
    def run_next_task
      if @tasks.empty?
        sleep 5.0
        return
      end
      
      # get the next task to be executed, which is the task with the lowest (ie, soonest)
      # next invocation time.
      task = next_task
      
      # sleep in chunks no longer than 1 second
      while Time.now < task.next_invocation_time
        
        # sleep until this next task's scheduled invocation time
        sleep_time = task.next_invocation_time - Time.now
        sleep sleep_time if sleep_time > 0
        return if !keep_running
      end
      
      begin
        task.execute
      rescue ServerError => e
        log.debug "Server Error: #{e}"
      rescue NewRelic::Agent::ForceRestartException => e
        # blow out the loop
        raise
      rescue RuntimeError => e
        # This is probably a server error which has been logged in the server along
        # with your account name.  Check and see if the agent listener is in the
        # stack trace and log it quietly if it is.
        message = "Error running task in worker loop, likely a server error (#{e})"
        if e.backtrace.grep(/agent_listener/).empty?
          log.error message
        else
          log.debug message
          log.debug e.backtrace.join("\n")
        end
      rescue Timeout::Error, NewRelic::Agent::IgnoreSilentlyException
        # Want to ignore these because they are handled already
      rescue ScriptError, StandardError => e 
        log.error "Error running task in Agent Worker Loop '#{e}': #{e.backtrace.first}" 
        log.debug e.backtrace.join("\n")
      end
    end
    
    class LoopTask
      
      def initialize(call_period, desc="", &task_proc) 
        @call_period = call_period
        @last_invocation_time = Time.now
        @task = task_proc
        @desc = desc
      end
      def to_s
        "Task[#{@desc}]"
      end
      def next_invocation_time
        @last_invocation_time + @call_period
      end
      
      def execute
        @last_invocation_time = Time.now
        @task.call
      end
    end
  end
end
