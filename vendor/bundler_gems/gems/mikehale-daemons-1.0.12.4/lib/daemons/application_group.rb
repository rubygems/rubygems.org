
module Daemons
  class ApplicationGroup
  
    attr_reader :app_name
    attr_reader :script
    
    attr_reader :monitor
    
    #attr_reader :controller
    
    attr_reader :options
    
    attr_reader :applications
    
    attr_accessor :controller_argv
    attr_accessor :app_argv
    
    attr_accessor :dir_mode
    attr_accessor :dir
    
    # true if the application is supposed to run in multiple instances
    attr_reader :multiple
    
    
    def initialize(app_name, options = {})
      @app_name = app_name
      @options = options
      
      if options[:script]
        @script = File.expand_path(options[:script])
      end
      
      #@controller = controller
      @monitor = nil
      
      #options = controller.options
      
      @multiple = options[:multiple] || false
      
      @dir_mode = options[:dir_mode] || :script
      @dir = options[:dir] || ''
      
      @keep_pid_files = options[:keep_pid_files] || false
      
      #@applications = find_applications(pidfile_dir())
      @applications = []
    end
    
    # Setup the application group.
    # Currently this functions calls <tt>find_applications</tt> which finds
    # all running instances of the application and populates the application array.
    #
    def setup
      @applications = find_applications(pidfile_dir())
    end
    
    def pidfile_dir
      PidFile.dir(@dir_mode, @dir, script)
    end  
    
    def find_applications(dir)
      pid_files = PidFile.find_files(dir, app_name, ! @keep_pid_files)
      
      #pp pid_files
      
      @monitor = Monitor.find(dir, app_name + '_monitor')
      
      pid_files.reject! {|f| f =~ /_monitor.pid$/}
      
      return pid_files.map {|f|
        app = Application.new(self, {}, PidFile.existing(f))
        setup_app(app)
        app
      }
    end
    
    def new_application(add_options = {})
      if @applications.size > 0 and not @multiple
        if options[:force]
          @applications.delete_if {|a|
            unless a.running?
              a.zap
              true
            end
          }
        end
        
        raise RuntimeException.new('there is already one or more instance(s) of the program running') unless @applications.empty?
      end
      
      app = Application.new(self, add_options)
      
      setup_app(app)
      
      @applications << app
      
      return app
    end
    
    def setup_app(app)
      app.controller_argv = @controller_argv
      app.app_argv = @app_argv
    end
    private :setup_app
    
    def create_monitor(an_app)
      return if @monitor
      
      if options[:monitor]
        @monitor = Monitor.new(an_app)

        @monitor.start(@applications)
      end
    end
    
    def start_all
      @monitor.stop if @monitor
      @monitor = nil
      
      @applications.each {|a| 
        fork { 
          a.start 
        } 
      }
    end
    
    # Specify :force_kill_wait => (seconds to wait) and this method will
    # block until the process is dead.  It first sends a TERM signal, then
    # a KILL signal (-9) if the process hasn't died after the wait time.
    # Note: The force argument is from the original daemons implementation.
    def stop_all(force = false)
      @monitor.stop if @monitor
      
      failed_to_kill = false
      debug = options[:debug]
      wait = options[:force_kill_wait].to_i
      pids = unix_pids
      if wait > 0 && pids.size > 0
        puts "[daemons_ext]: Killing #{app_name} with force after #{wait} secs."
        STDOUT.flush

        # Send term first, don't delete PID files.
        pids.each {|pid| Process.kill('TERM', pid) rescue Errno::ESRCH}

        begin
          Timeout::timeout(wait) {block_on_pids(wait, debug, options[:sleepy_time] || 1)}
        rescue Timeout::Error
          puts "[daemons_ext]: Time is up! Forcefully killing #{unix_pids.size} #{app_name}(s)..."
          STDOUT.flush
          unix_pids.each {|pid| `kill -9 #{pid}`}
          begin
            # Give it an extra 30 seconds to kill -9
            Timeout::timeout(30) {block_on_pids(wait, debug, options[:sleepy_time] || 1)}
          rescue Timeout::Error
            failed_to_kill = true
            puts "[daemons_ext]: #{unix_pids} #{app_name}(s) won't die! Giving up."
            STDOUT.flush
          end
        ensure
          # Delete Pidfiles
          @applications.each {|a| a.zap!}
        end

        puts "[daemons_ext]: All #{app_name}s dead." unless failed_to_kill
        STDOUT.flush
      else
        @applications.each {|a| 
          if force
            begin; a.stop; rescue ::Exception; end
          else
            a.stop
          end
        }
      end
    end
    
    def zap_all
      @monitor.stop if @monitor
      
      @applications.each {|a| a.zap}
    end
    
    def show_status
      @applications.each {|a| a.show_status}
    end
    
    private

    # Block until all unix_pids are gone (should be wrapped in a timeout)
    def block_on_pids(wait, debug, sleepy_time = 1)
      started_at = Time.now
      num_pids = unix_pids.size
      while num_pids > 0
        time_left = wait - (Time.now - started_at)
        puts "[daemons_ext]: Waiting #{time_left.round} secs on " +
              "#{num_pids} #{app_name}(s)..."
        unix_pids.each {|pid| puts "\t#{pid}"} if debug
        STDOUT.flush
        sleep sleepy_time
        num_pids = unix_pids.size
      end 
    end

    # Find UNIX pids based on app_name.  CAUTION: This has only been tested on
    # Mac OS X and CentOS.
    def unix_pids
      pids = []
      x = `ps auxw | grep -v grep | awk '{print $2, $11}' | grep #{app_name}`
      if x && x.chomp!
        processes = x.split(/\n/).compact
        processes = processes.delete_if do |p|
          pid, name = p.split(/\s/)
          # We want to make sure that the first part of the process name matches
          # so that app_name matches app_name_22
          app_name != name[0..(app_name.length - 1)]
        end
        pids = processes.map {|p| p.split(/\s/)[0].to_i}
      end

      pids
    end
    
  end

end