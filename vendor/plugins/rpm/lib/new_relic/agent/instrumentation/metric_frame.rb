# A struct holding the information required to measure a controller
# action.  This is put on the thread local.  Handles the issue of
# re-entrancy, or nested action calls.
#
# This class is not part of the public API.  Avoid making calls on it directly.
#
class NewRelic::Agent::Instrumentation::MetricFrame 
  attr_accessor :start, :apdex_start, :exception, 
                :filtered_params, :available_request, :force_flag, 
                :jruby_cpu_start, :process_cpu_start, :database_metric_name
  
  # Return the currently active metric frame, or nil.  Call with +true+
  # to create a new metric frame if one is not already on the thread.
  def self.current(create_if_empty=nil)
    Thread.current[:newrelic_metric_frame] ||= create_if_empty && new
  end
  
  # This is the name of the model currently assigned to database 
  # measurements, overriding the default. 
  def self.database_metric_name
    current && current.database_metric_name
  end
  
  @@java_classes_loaded = false
  
  if defined? JRuby
    begin
      require 'java'
      include_class 'java.lang.management.ManagementFactory'
      include_class 'com.sun.management.OperatingSystemMXBean'
      @@java_classes_loaded = true
    rescue Exception => e
    end
  end
  
  attr_reader :depth
  
  def initialize
    @start = Time.now.to_f
    @path_stack = [] # stack of [controller, path] elements
    @jruby_cpu_start = jruby_cpu_time
    @process_cpu_start = process_cpu
  end

  # Indicate that we are entering a measured controller action or task.
  # Make sure you unwind every push with a pop call.
  def push(category, path)
    @path_stack.push [category, path]
  end
  
  # Indicate that you don't want to keep the currently saved transaction
  # information
  def self.abort_transaction!
    current.abort_transaction! if current
  end
  
  # Call this to ensure that the current transaction is not saved
  def abort_transaction!
    NewRelic::Agent.instance.transaction_sampler.ignore_transaction
  end
  # This needs to be called after entering the call to trace the controller action, otherwise
  # the controller action blames itself.  It gets reset in the normal #pop call.
  def start_transaction
    NewRelic::Agent.instance.stats_engine.start_transaction metric_name
    # Only push the transaction context info once, on entry:
    if @path_stack.size == 1
      NewRelic::Agent.instance.transaction_sampler.notice_transaction(metric_name, available_request, filtered_params)
    end
  end
  
  def category
    @path_stack.last.first  
  end
  def path
    @path_stack.last.last
  end
  
  def pop
    category, path = @path_stack.pop
    if category.nil?
      NewRelic::Control.instance.log.error "Underflow in metric frames: #{caller.join("\n   ")}"
    end
    # change the transaction name back to whatever was on the stack.  
    if @path_stack.empty?
      Thread.current[:newrelic_metric_frame] = nil
      if NewRelic::Agent.is_execution_traced?
        cpu_burn = nil
        if @process_cpu_start
          cpu_burn = process_cpu - @process_cpu_start
        elsif @jruby_cpu_start
          cpu_burn = jruby_cpu_time - @jruby_cpu_start
          NewRelic::Agent.get_stats_no_scope(NewRelic::Metrics::USER_TIME).record_data_point(cpu_burn)
        end
        NewRelic::Agent.instance.transaction_sampler.notice_transaction_cpu_time(cpu_burn) if cpu_burn
        NewRelic::Agent.instance.histogram.process(Time.now.to_f - start) if recording_web_transaction?(category)
      end      
    end
    NewRelic::Agent.instance.stats_engine.scope_name = metric_name 
  end
  
  # If we have an active metric frame, notice the error and increment the error metric.
  def self.notice_error(e, custom_params={})
    if current
      current.notice_error(e, custom_params)
    else
      NewRelic::Agent.instance.error_collector.notice_error(e, nil, nil, custom_params)
    end
  end
  
  def notice_error(e, custom_params={})
    if exception != e
      NewRelic::Agent.instance.error_collector.notice_error(e, nil, metric_name, filtered_params.merge(custom_params))
      self.exception = e
    end
  end
  def record_apdex
    return unless recording_web_transaction?
    ending = Time.now.to_f
    summary_stat = NewRelic::Agent.instance.stats_engine.get_custom_stats("Apdex", NewRelic::ApdexStats)
    controller_stat = NewRelic::Agent.instance.stats_engine.get_custom_stats("Apdex/#{path}", NewRelic::ApdexStats)
    update_apdex(summary_stat, ending - apdex_start, exception)
    update_apdex(controller_stat, ending - start, exception)
  end
  
  def metric_name
    return nil if @path_stack.empty?
    category + '/' + path 
  end
  
  # Return the array of metrics to record for the current metric frame.
  def recorded_metrics
    metrics = [ metric_name ]
    if @path_stack.size == 1
      if recording_web_transaction?
        metrics += ["Controller", "HttpDispatcher"]
      else
        metrics += ["#{category}/all", "OtherTransaction/all"]
      end
    end
    metrics
  end

  # Yield to a block that is run with a database metric name context.  This means
  # the Database instrumentation will use this for the metric name if it does not
  # otherwise know about a model.  This is re-entrant.
  #
  # * <tt>model</tt> is the DB model class
  # * <tt>method</tt> is the name of the finder method or other method to identify the operation with.
  #
  def with_database_metric_name(model, method)
    previous = @database_metric_name
    model_name = case model
    when Class
      model.name
    when String
      model
    else
      model.to_s
    end
    @database_metric_name = "ActiveRecord/#{model_name}/#{method}"
    yield
  ensure  
    @database_metric_name=previous
  end
  
  private
  
  def recording_web_transaction?(cat = category)
    0 == cat.index("Controller")
  end
  
  def update_apdex(stat, duration, failed)
    apdex_t = NewRelic::Control.instance.apdex_t
    case
    when failed
      stat.record_apdex_f
    when duration <= apdex_t
      stat.record_apdex_s
    when duration <= 4 * apdex_t
      stat.record_apdex_t
    else
      stat.record_apdex_f
    end
  end  
  
  def process_cpu
    return nil if defined? JRuby
    p = Process.times
    p.stime + p.utime
  end
  
  def jruby_cpu_time # :nodoc:
    return nil unless @@java_classes_loaded
    threadMBean = ManagementFactory.getThreadMXBean()
    java_utime = threadMBean.getCurrentThreadUserTime()  # ns
    -1 == java_utime ? 0.0 : java_utime/1e9
  end
  
end