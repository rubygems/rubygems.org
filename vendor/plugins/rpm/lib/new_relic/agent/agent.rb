require 'socket'
require 'net/https' 
require 'net/http'
require 'logger'
require 'zlib'
require 'stringio'

# The NewRelic Agent collects performance data from ruby applications
# in realtime as the application runs, and periodically sends that
# data to the NewRelic server.
module NewRelic::Agent
  
  # The Agent is a singleton that is instantiated when the plugin is
  # activated.
  class Agent
    
    # Specifies the version of the agent's communication protocol with
    # the NewRelic hosted site.
    
    PROTOCOL_VERSION = 8
    
    attr_reader :obfuscator
    attr_reader :stats_engine
    attr_reader :transaction_sampler
    attr_reader :error_collector
    attr_reader :task_loop
    attr_reader :record_sql
    attr_reader :histogram
    attr_reader :metric_ids
    attr_reader :should_send_errors
    
    # Should only be called by NewRelic::Control
    def self.instance
      @instance ||= self.new
    end
    # This method is deprecated.  Use NewRelic::Agent.manual_start
    def manual_start(ignored=nil, also_ignored=nil)
      raise "This method no longer supported.  Instead use the class method NewRelic::Agent.manual_start"
    end
    
    # this method makes sure that the agent is running. it's important
    # for passenger where processes are forked and the agent is
    # dormant
    #
    def ensure_worker_thread_started
      return unless control.agent_enabled? && control.monitor_mode? && !@invalid_license
      if !running?
        log.info "Detected that the worker loop is not running.  Restarting."
        # Assume we've been forked, clear out stats that are left over from parent process
        reset_stats
        launch_worker_thread
        @stats_engine.spawn_sampler_thread
      end
    end
    
    # True if the worker thread has been started.  Doesn't necessarily
    # mean we are connected
    def running?
      control.agent_enabled? && control.monitor_mode? && @task_loop && @task_loop.pid == $$
    end
    
    # True if we have initialized and completed 'start'
    def started?
      @started
    end
    
    # Attempt a graceful shutdown of the agent.  
    def shutdown
      return if not started?
      if @task_loop
        @task_loop.stop
        
        log.debug "Starting Agent shutdown"
        
        # if litespeed, then ignore all future SIGUSR1 - it's
        # litespeed trying to shut us down
        
        if control.dispatcher == :litespeed
          Signal.trap("SIGUSR1", "IGNORE")
          Signal.trap("SIGTERM", "IGNORE")
        end
        
        begin
          graceful_disconnect
        rescue => e
          log.error e
          log.error e.backtrace.join("\n")
        end
      end
      @started = nil
    end
    
    def start_transaction
      Thread::current[:custom_params] = nil
      @stats_engine.start_transaction
    end
    
    def end_transaction
      Thread::current[:custom_params] = nil
      @stats_engine.end_transaction
    end
    
    def set_record_sql(should_record)
      prev = Thread::current[:record_sql]
      Thread::current[:record_sql] = should_record
      prev.nil? || prev
    end
    
    def set_record_tt(should_record)
      prev = Thread::current[:record_tt]
      Thread::current[:record_tt] = should_record
      prev.nil? || prev
    end
    # Push flag indicating whether we should be tracing in this
    # thread.  
    def push_trace_execution_flag(should_trace=false)
      (Thread.current[:newrelic_untraced] ||= []) << should_trace 
    end

    # Pop the current trace execution status.  Restore trace execution status
    # to what it was before we pushed the current flag.
    def pop_trace_execution_flag
      Thread.current[:newrelic_untraced].pop if Thread.current[:newrelic_untraced]
    end
    
    def add_custom_parameters(params)
      p = Thread::current[:custom_params] || (Thread::current[:custom_params] = {})
      
      p.merge!(params)
    end
    
    def custom_params
      Thread::current[:custom_params] || {}
    end
    
    def set_sql_obfuscator(type, &block)
      if type == :before
        @obfuscator = NewRelic::ChainedCall.new(block, @obfuscator)
      elsif type == :after
        @obfuscator = NewRelic::ChainedCall.new(@obfuscator, block)
      elsif type == :replace
        @obfuscator = block
      else
        fail "unknown sql_obfuscator type #{type}"
      end
    end

    def log
      NewRelic::Control.instance.log
    end  
    
    # Start up the agent.  This verifies that the agent_enabled? is
    # true and initializes the sampler based on the current
    # controluration settings.  Then it will fire up the background
    # thread for sending data to the server if applicable.
    def start
      if started?
        control.log! "Agent Started Already!", :error
        return
      end
      return if !control.agent_enabled? 

      @local_host = determine_host
      
      log.info "Web container: #{control.dispatcher.to_s}"
      
      @started = true
      
      sampler_config = control.fetch('transaction_tracer', {})
      @use_transaction_sampler = sampler_config.fetch('enabled', true)
      
      @record_sql = sampler_config.fetch('record_sql', :obfuscated).to_sym
      
      # use transaction_threshold: 4.0 to force the TT collection
      # threshold to 4 seconds
      # use transaction_threshold: apdex_f to use your apdex t value
      # multiplied by 4
      # undefined transaction_threshold defaults to 2.0
      apdex_f = 4 * NewRelic::Control.instance.apdex_t
      @slowest_transaction_threshold = sampler_config.fetch('transaction_threshold', 2.0)
      if @slowest_transaction_threshold =~ /apdex_f/i
        @slowest_transaction_threshold = apdex_f
      end
      @slowest_transaction_threshold = @slowest_transaction_threshold.to_f
      
      if @use_transaction_sampler
        log.info "Transaction tracing threshold is #{@slowest_transaction_threshold} seconds." 
      else
        log.info "Transaction tracing not enabled."
      end
      @explain_threshold = sampler_config.fetch('explain_threshold', 0.5).to_f
      @explain_enabled = sampler_config.fetch('explain_enabled', true)
      @random_sample = sampler_config.fetch('random_sample', false)
      log.warn "Agent is configured to send raw SQL to RPM service" if @record_sql == :raw
      # Initialize transaction sampler
      @transaction_sampler.random_sampling = @random_sample

      if control.monitor_mode?
        if !control.license_key
          @invalid_license = true
          control.log! "No license key found.  Please edit your newrelic.yml file and insert your license key.", :error
        elsif  control.license_key.length != 40
          @invalid_license = true
          control.log! "Invalid license key: #{control.license_key}", :error
        else     
          launch_worker_thread
          # When the VM shuts down, attempt to send a message to the
          # server that this agent run is stopping, assuming it has
          # successfully connected
          # This shutdown handler doesn't work if Sinatra is running
          # because it executes in the shutdown handler!
          at_exit { shutdown } unless [:sinatra, :unicorn].include? NewRelic::Control.instance.dispatcher
        end
      end
      control.log! "New Relic RPM Agent #{NewRelic::VERSION::STRING} Initialized: pid = #{$$}"
      control.log! "Agent Log found in #{NewRelic::Control.instance.log_file}" if NewRelic::Control.instance.log_file
    end

    private
    def collector
      @collector ||= control.server
    end
    
    # Connect to the server, and run the worker loop forever.
    # Will not return.
    def run_task_loop
      # determine the reporting period (server based)          
      # note if the agent attempts to report more frequently than
      # the specified report data, then it will be ignored.
      
      control.log! "Reporting performance data every #{@report_period} seconds."        
      @task_loop.add_task(@report_period, "Timeslice Data Send") do 
        harvest_and_send_timeslice_data
      end
      
      if @should_send_samples && @use_transaction_sampler
        @task_loop.add_task(@report_period, "Transaction Sampler Send") do 
          harvest_and_send_slowest_sample
        end
      elsif !control.developer_mode?
        # We still need the sampler for dev mode.
        @transaction_sampler.disable
      end
      
      if @should_send_errors && @error_collector.enabled
        @task_loop.add_task(@report_period, "Error Send") do 
          harvest_and_send_errors
        end
      end
      log.debug("Running worker loop")
      @task_loop.run
    rescue StandardError
      log.debug("Error in worker loop: #{$!}")
      @connected = false
      raise
    end
    
    def launch_worker_thread
      if (control.dispatcher == :passenger && $0 =~ /ApplicationSpawner/)
        log.debug "Process is passenger spawner - don't connect to RPM service"
        return
      end
      
      @task_loop = WorkerLoop.new(log)
      
      if control['check_bg_loading']
        log.warn "Agent background loading checking turned on"
        require 'new_relic/agent/patch_const_missing'
        ClassLoadingWatcher.enable_warning
      end
      log.debug "Creating RPM worker thread."
      @worker_thread = Thread.new do
        begin
          ClassLoadingWatcher.background_thread=Thread.current if control['check_bg_loading']
          NewRelic::Agent.disable_all_tracing do
            connect
            run_task_loop if @connected
          end
        rescue NewRelic::Agent::ForceRestartException => e
          log.info e.message
          # disconnect and start over.
          # clear the stats engine
          reset_stats
          @connected = false
          # Wait a short time before trying to reconnect
          sleep 30
          retry
        rescue IgnoreSilentlyException
          control.log! "Unable to establish connection with the server.  Run with log level set to debug for more information."
        rescue Exception => e
          @connected = false
          control.log! e, :error
          control.log! e.backtrace.join("\n  "), :error
        end
      end
      @worker_thread['newrelic_label'] = 'Worker Loop'
    end
    
    def control
      NewRelic::Control.instance
    end
    
    def initialize
      @connected = false
      @launch_time = Time.now
      
      @metric_ids = {}
      @histogram = NewRelic::Histogram.new(NewRelic::Control.instance.apdex_t / 10)
      @stats_engine = NewRelic::Agent::StatsEngine.new
      @transaction_sampler = NewRelic::Agent::TransactionSampler.new
      @stats_engine.transaction_sampler = @transaction_sampler
      @error_collector = NewRelic::Agent::ErrorCollector.new
      
      @request_timeout = NewRelic::Control.instance.fetch('timeout', 2 * 60)
      
      @invalid_license = false
      
      @last_harvest_time = Time.now
      @obfuscator = method(:default_sql_obfuscator)
    end
    
    # Connect to the server and validate the license.  If successful,
    # @connected has true when finished.  If not successful, you can
    # keep calling this.  Return false if we could not establish a
    # connection with the server and we should not retry, such as if
    # there's a bad license key.
    def connect
      # wait a few seconds for the web server to boot, necessary in development
      connect_retry_period = 5
      connect_attempts = 0
      @agent_id = nil
      begin
        sleep connect_retry_period.to_i
        environment = control['send_environment_info'] != false ? control.local_env.snapshot : []
        @agent_id ||= invoke_remote :start, @local_host, {
          :pid => $$, 
          :launch_time => @launch_time.to_f, 
          :agent_version => NewRelic::VERSION::STRING, 
          :environment => environment,
          :settings => control.settings,
          :validate_seed => ENV['NR_VALIDATE_SEED'],
          :validate_token => ENV['NR_VALIDATE_TOKEN'] }
        
        host = invoke_remote(:get_redirect_host)
        
        @collector = control.server_from_host(host) if host        
            
        @report_period = invoke_remote :get_data_report_period, @agent_id
 
        control.log! "Connected to NewRelic Service at #{@collector}"
        log.debug "Agent ID = #{@agent_id}."
        
        # Ask the server for permission to send transaction samples.
        # determined by subscription license.
        @should_send_samples = invoke_remote :should_collect_samples, @agent_id
        
        if @should_send_samples
          sampling_rate = invoke_remote :sampling_rate, @agent_id if @random_sample
          @transaction_sampler.sampling_rate = sampling_rate
          log.info "Transaction sample rate: #{@transaction_sampler.sampling_rate}" if sampling_rate
        end
        
        # Ask for permission to collect error data
        @should_send_errors = invoke_remote :should_collect_errors, @agent_id
        
        log.info "Transaction traces will be sent to the RPM service" if @use_transaction_sampler && @should_send_samples
        log.info "Errors will be sent to the RPM service" if @error_collector.enabled && @should_send_errors
        
        @connected = true
        
      rescue LicenseException => e
        control.log! e.message, :error
        control.log! "Visit NewRelic.com to obtain a valid license key, or to upgrade your account."
        @invalid_license = true
        return false
        
      rescue Timeout::Error, StandardError => e
        log.info "Unable to establish connection with New Relic RPM Service at #{control.server}"
        unless e.instance_of? IgnoreSilentlyException
          log.error e.message
          log.debug e.backtrace.join("\n")
        end
        # retry logic
        connect_attempts += 1
        case connect_attempts
          when 1..2
          connect_retry_period, period_msg = 60, "1 minute"
          when 3..5 then
          connect_retry_period, period_msg = 60 * 2, "2 minutes"
        else 
          connect_retry_period, period_msg = 10*60, "10 minutes"
        end
        log.info "Will re-attempt in #{period_msg}" 
        retry
      end
    end
      
    def determine_host
      Socket.gethostname
    end
    
    def determine_home_directory
      control.root
    end
    def reset_stats
      @stats_engine.reset_stats
      @metric_ids = {}
      @unsent_errors = []
      @traces = nil
      @unsent_timeslice_data = {}
      @last_harvest_time = Time.now
      @launch_time = Time.now
      @histogram = NewRelic::Histogram.new(NewRelic::Control.instance.apdex_t / 10)
    end
    
    def harvest_and_send_timeslice_data
      
      NewRelic::Agent::BusyCalculator.harvest_busy
      
      now = Time.now
            
      @unsent_timeslice_data ||= {}
      @unsent_timeslice_data = @stats_engine.harvest_timeslice_data(@unsent_timeslice_data, @metric_ids)
      
      begin
        # In this version of the protocol, we get back an assoc array of spec to id.
        metric_ids = invoke_remote(:metric_data, @agent_id, 
                                   @last_harvest_time.to_f, 
                                   now.to_f, 
                                   @unsent_timeslice_data.values)
        
      rescue Timeout::Error
        # assume that the data was received. chances are that it was
        metric_ids = nil
      end
      
      metric_ids.each do | spec, id |
        @metric_ids[spec] = id
      end if metric_ids 
      
      log.debug "#{now}: sent #{@unsent_timeslice_data.length} timeslices (#{@agent_id}) in #{Time.now - now} seconds"
      
      # if we successfully invoked this web service, then clear the unsent message cache.
      @unsent_timeslice_data = {}
      @last_harvest_time = now
      
      # handle_messages 
      
      # note - exceptions are logged in invoke_remote.  If an exception is encountered here,
      # then the metric data is downsampled for another timeslices
    end
    
    def harvest_and_send_slowest_sample
      @traces = @transaction_sampler.harvest(@traces, @slowest_transaction_threshold)
      
      unless @traces.empty?
        now = Time.now
        log.debug "Sending (#{@traces.length}) transaction traces"
        begin        
          # take the traces and prepare them for sending across the
          # wire.  This includes gathering SQL explanations, stripping
          # out stack traces, and normalizing SQL.  note that we
          # explain only the sql statements whose segments' execution
          # times exceed our threshold (to avoid unnecessary overhead
          # of running explains on fast queries.)
          traces = @traces.collect {|trace| trace.prepare_to_send(:explain_sql => @explain_threshold, :record_sql => @record_sql, :keep_backtraces => true, :explain_enabled => @explain_enabled)} 
          invoke_remote :transaction_sample_data, @agent_id, traces
        rescue PostTooBigException
          # we tried to send too much data, drop the first trace and
          # try again
          retry if @traces.shift
        end
        
        log.debug "#{now}: sent slowest sample (#{@agent_id}) in #{Time.now - now} seconds"
      end
      
      # if we succeed sending this sample, then we don't need to keep
      # the slowest sample around - it has been sent already and we
      # can collect the next one
      @traces = nil
      
      # note - exceptions are logged in invoke_remote.  If an
      # exception is encountered here, then the slowest sample of is
      # determined of the entire period since the last reported
      # sample.
    end
    
    def harvest_and_send_errors
      @unsent_errors = @error_collector.harvest_errors(@unsent_errors)
      if @unsent_errors && @unsent_errors.length > 0
        log.debug "Sending #{@unsent_errors.length} errors"
        begin        
          invoke_remote :error_data, @agent_id, @unsent_errors
        rescue PostTooBigException
          @unsent_errors.shift
          retry
        end
        # if the remote invocation fails, then we never clear
        # @unsent_errors, and therefore we can re-attempt to send on
        # the next heartbeat.  Note the error collector maxes out at
        # 20 instances to prevent leakage
        @unsent_errors = []
      end
    end

    def compress_data(object)
      dump = Marshal.dump(object)
      
      # this checks to make sure mongrel won't choke on big uploads
      check_post_size(dump)
      
      # we currently optimize for CPU here since we get roughly a 10x
      # reduction in message size with this, and CPU overhead is at a
      # premium. For extra-large posts, we use the higher compression
      # since otherwise it actually errors out.
      
      dump_size = dump.size
      
      # small payloads don't need compression      
      return [dump, 'identity'] if dump_size < 2000
      
      # medium payloads get fast compression, to save CPU
      # big payloads get all the compression possible, to stay under
      # the 2,000,000 byte post threshold      
      compression = dump_size < 2000000 ? Zlib::BEST_SPEED : Zlib::BEST_COMPRESSION
      
      [Zlib::Deflate.deflate(dump, compression), 'deflate']
    end
    
    def check_post_size(post_string)
      # TODO: define this as a config option on the server side
      return if post_string.size < control.post_size_limit
      log.warn "Tried to send too much data: #{post_string.size} bytes"
      raise PostTooBigException
    end

    def send_request(opts)
      request = Net::HTTP::Post.new(opts[:uri], 'CONTENT-ENCODING' => opts[:encoding], 'ACCEPT-ENCODING' => 'gzip', 'HOST' => opts[:collector].name)
      request.content_type = "application/octet-stream"
      request.body = opts[:data]
      
      log.debug "connect to #{opts[:collector]}#{opts[:uri]}"
      
      response = nil
      http = control.http_connection(collector)      
      begin
        timeout(@request_timeout) do      
          response = http.request(request)
        end
      rescue Timeout::Error
        log.warn "Timed out trying to post data to RPM (timeout = #{@request_timeout} seconds)" unless @request_timeout < 30
        raise
      end
      if response.is_a? Net::HTTPServiceUnavailable
        log.debug(response.body || response.message)
        raise IgnoreSilentlyException
      elsif response.is_a? Net::HTTPGatewayTimeOut
        log.debug("Timed out getting response: #{response.message}")
        raise Timeout::Error, response.message
      elsif !(response.is_a? Net::HTTPSuccess)
        log.debug "Unexpected response from server: #{response.code}: #{response.message}"
        raise IgnoreSilentlyException
      end
      response
    end

    def decompress_response(response)
      if response['content-encoding'] != 'gzip'
        log.debug "Uncompressed content returned"
        return response.body
      end
      log.debug "Decompressing return value"
      i = Zlib::GzipReader.new(StringIO.new(response.body))
      i.read
    end

    def check_for_exception(response)
      dump = decompress_response(response)
      value = Marshal.load(dump)
      raise value if value.is_a? Exception
      value
    end
    
    def remote_method_uri(method)
      uri = "/agent_listener/#{PROTOCOL_VERSION}/#{control.license_key}/#{method}"
      uri << "?run_id=#{@agent_id}" if @agent_id
      uri
    end
      
    # send a message via post
    def invoke_remote(method, *args)
      #determines whether to zip the data or send plain
      post_data, encoding = compress_data(args)
      
      response = send_request({:uri => remote_method_uri(method), :encoding => encoding, :collector => collector, :data => post_data})

      # raises the right exception if the remote server tells it to die
      return check_for_exception(response)
    rescue ForceRestartException => e
      log.info e.message
      raise
    rescue ForceDisconnectException => e
      log.error "RPM forced this agent to disconnect (#{e.message})\n" \
      "Restart this process to resume monitoring via rpm.newrelic.com."
      # when a disconnect is requested, stop the current thread, which
      # is the worker thread that gathers data and talks to the
      # server.
      @connected = false
      Thread.exit
    rescue SystemCallError, SocketError => e
      # These include Errno connection errors 
      log.debug "Recoverable error connecting to the server: #{e}"
      raise IgnoreSilentlyException
    end
    
    def graceful_disconnect
      if @connected && !control.developer_mode?
        begin
          log.debug "Sending graceful shutdown message to #{control.server}"
          
          @request_timeout = 10
          
          log.debug "Sending RPM service agent run shutdown message"
          invoke_remote :shutdown, @agent_id, Time.now.to_f
          
          log.debug "Graceful shutdown complete"
          
        rescue Timeout::Error, StandardError 
        end
      else
        log.debug "Bypassing graceful shutdown - agent not connected"
      end
    end
    def default_sql_obfuscator(sql)
      sql = sql.dup
      # This is hardly readable.  Use the unit tests.
      # remove single quoted strings:
      sql.gsub!(/'(.*?[^\\'])??'(?!')/, '?')
      # remove double quoted strings:
      sql.gsub!(/"(.*?[^\\"])??"(?!")/, '?')
      # replace all number literals
      sql.gsub!(/\d+/, "?")
      sql
    end
  end
  
end
