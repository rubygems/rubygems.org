module AWS
  module S3
    # A bucket can be set to log the requests made on it. By default logging is turned off. You can check if a bucket has logging enabled:
    # 
    #   Bucket.logging_enabled_for? 'jukebox'
    #   # => false
    # 
    # Enabling it is easy:
    # 
    #   Bucket.enable_logging_for('jukebox')
    # 
    # Unless you specify otherwise, logs will be written to the bucket you want to log. The logs are just like any other object. By default they will start with the prefix 'log-'. You can customize what bucket you want the logs to be delivered to, as well as customize what the log objects' key is prefixed with by setting the <tt>target_bucket</tt> and <tt>target_prefix</tt> option:
    # 
    #   Bucket.enable_logging_for(
    #     'jukebox', 'target_bucket' => 'jukebox-logs'
    #   )
    # 
    # Now instead of logging right into the jukebox bucket, the logs will go into the bucket called jukebox-logs.
    # 
    # Once logs have accumulated, you can access them using the <tt>logs</tt> method:
    # 
    #   pp Bucket.logs('jukebox')
    #   [#<AWS::S3::Logging::Log '/jukebox-logs/log-2006-11-14-07-15-24-2061C35880A310A1'>,
    #    #<AWS::S3::Logging::Log '/jukebox-logs/log-2006-11-14-08-15-27-D8EEF536EC09E6B3'>,
    #    #<AWS::S3::Logging::Log '/jukebox-logs/log-2006-11-14-08-15-29-355812B2B15BD789'>]
    #
    # Each log has a <tt>lines</tt> method that gives you information about each request in that log. All the fields are available 
    # as named methods. More information is available in Logging::Log::Line.
    #
    #   logs = Bucket.logs('jukebox')
    #   log  = logs.first
    #   line = log.lines.first
    #   line.operation
    #   # => 'REST.GET.LOGGING_STATUS'
    #   line.request_uri
    #   # => 'GET /jukebox?logging HTTP/1.1'
    #   line.remote_ip
    #   # => "67.165.183.125"
    #
    # Disabling logging is just as simple as enabling it:
    #
    #  Bucket.disable_logging_for('jukebox')
    module Logging
      # Logging status captures information about the calling bucket's logging settings. If logging is enabled for the bucket
      # the status object will indicate what bucket the logs are written to via the <tt>target_bucket</tt> method as well as
      # the logging key prefix with via <tt>target_prefix</tt>.
      #
      # See the documentation for Logging::Management::ClassMethods for more information on how to get the logging status of a bucket. 
      class Status
        include SelectiveAttributeProxy
        attr_reader :enabled
        alias_method :logging_enabled?, :enabled
      
        def initialize(attributes = {}) #:nodoc:
          attributes  = {'target_bucket' => nil, 'target_prefix' => nil}.merge(attributes)
          @enabled    = attributes.has_key?('logging_enabled')
          @attributes = attributes.delete('logging_enabled') || attributes
        end
      
        def to_xml #:nodoc:
          Builder.new(self).to_s
        end
      
        private
          attr_reader :attributes
        
          class Builder < XmlGenerator #:nodoc:
            attr_reader :logging_status
            def initialize(logging_status)
              @logging_status = logging_status
              super()
            end
          
            def build
              xml.tag!('BucketLoggingStatus', 'xmlns' => 'http://s3.amazonaws.com/doc/2006-03-01/') do
                if logging_status.target_bucket && logging_status.target_prefix
                  xml.LoggingEnabled do
                    xml.TargetBucket logging_status.target_bucket
                    xml.TargetPrefix logging_status.target_prefix
                  end
                end
              end
            end
          end
        end
      
      # A bucket log exposes requests made on the given bucket. Lines of the log represent a single request. The lines of a log
      # can be accessed with the lines method. 
      #
      #   log = Bucket.logs_for('marcel').first
      #   log.lines
      # 
      # More information about the logged requests can be found in the documentation for Log::Line.
      class Log
        def initialize(log_object) #:nodoc:
          @log = log_object
        end
        
        # Returns the lines for the log. Each line is wrapped in a Log::Line.
        if RUBY_VERSION >= '1.8.7'
          def lines
            log.value.lines.map {|line| Line.new(line)}
          end
        else
          def lines
            log.value.map {|line| Line.new(line)}
          end
        end
        memoized :lines
        
        def path
          log.path
        end
        
        def inspect #:nodoc:
          "#<%s:0x%s '%s'>" % [self.class.name, object_id, path]
        end
        
        private
          attr_reader :log
          
        # Each line of a log exposes the raw line, but it also has method accessors for all the fields of the logged request.
        #
        # The list of supported log line fields are listed in the S3 documentation: http://docs.amazonwebservices.com/AmazonS3/2006-03-01/LogFormat.html
        #
        #   line = log.lines.first
        #   line.remote_ip
        #   # => '72.21.206.5'
        #
        # If a certain field does not apply to a given request (for example, the <tt>key</tt> field does not apply to a bucket request),
        # or if it was unknown or unavailable, it will return <tt>nil</tt>.
        #
        #   line.operation
        #   # => 'REST.GET.BUCKET'
        #   line.key
        #   # => nil
        class Line < String
          DATE          = /\[([^\]]+)\]/
          QUOTED_STRING = /"([^"]+)"/
          REST          = /(\S+)/
          LINE_SCANNER  = /#{DATE}|#{QUOTED_STRING}|#{REST}/
          
          cattr_accessor :decorators
          @@decorators = Hash.new {|hash, key| hash[key] = lambda {|entry| CoercibleString.coerce(entry)}}
          cattr_reader   :fields
          @@fields     = []
          
          class << self
            def field(name, offset, type = nil, &block) #:nodoc:
              decorators[name] = block if block_given?
              fields << name
              class_eval(<<-EVAL, __FILE__, __LINE__)
                def #{name}
                  value = parts[#{offset} - 1]
                  if value == '-'
                    nil
                  else
                    self.class.decorators[:#{name}].call(value)
                  end
                end
                memoized :#{name}
              EVAL
            end
            
            # Time.parse doesn't like %d/%B/%Y:%H:%M:%S %z so we have to transform it unfortunately
            def typecast_time(datetime) #:nodoc:
              datetime.sub!(%r|^(\w{2})/(\w{3})/(\w{4})|, '\2 \1 \3')
              datetime.sub!(':', ' ')
              Time.parse(datetime)
            end
          end
          
          def initialize(line) #:nodoc:
            super(line)
            @parts = parse
          end
          
          field(:owner,            1)  {|entry| Owner.new('id' => entry) }
          field :bucket,           2
          field(:time,             3)  {|entry| typecast_time(entry)}
          field :remote_ip,        4
          field(:requestor,        5)  {|entry| Owner.new('id' => entry) }
          field :request_id,       6
          field :operation,        7
          field :key,              8
          field :request_uri,      9
          field :http_status,      10
          field :error_code,       11
          field :bytes_sent,       12
          field :object_size,      13
          field :total_time,       14
          field :turn_around_time, 15
          field :referrer,         16
          field :user_agent,       17
          
          # Returns all fields of the line in a hash of the form <tt>:field_name => :field_value</tt>.
          #
          #   line.attributes.values_at(:bucket, :key)
          #   # => ['marcel', 'kiss.jpg']
          def attributes
            self.class.fields.inject({}) do |attribute_hash, field|
              attribute_hash[field] = send(field)
              attribute_hash
            end
          end
          
          private
            attr_reader :parts
            
            def parse
              scan(LINE_SCANNER).flatten.compact
            end
        end
      end
      
      module Management #:nodoc:
        def self.included(klass) #:nodoc:
          klass.extend(ClassMethods)
          klass.extend(LoggingGrants)
        end
        
        module ClassMethods
          # Returns the logging status for the bucket named <tt>name</tt>. From the logging status you can determine the bucket logs are delivered to
          # and what the bucket object's keys are prefixed with. For more information see the Logging::Status class.
          #
          #   Bucket.logging_status_for 'marcel'
          def logging_status_for(name = nil, status = nil)
            if name.is_a?(Status)
              status = name
              name   = nil
            end

            path = path(name) << '?logging'
            status ? put(path, {}, status.to_xml) : Status.new(get(path).parsed)
          end
          alias_method :logging_status, :logging_status_for
          
          # Enables logging for the bucket named <tt>name</tt>. You can specify what bucket to log to with the <tt>'target_bucket'</tt> option as well
          # as what prefix to add to the log files with the <tt>'target_prefix'</tt> option. Unless you specify otherwise, logs will be delivered to
          # the same bucket that is being logged and will be prefixed with <tt>log-</tt>.
          def enable_logging_for(name = nil, options = {})
            name            = bucket_name(name)
            default_options = {'target_bucket' => name, 'target_prefix' => 'log-'}
            options         = default_options.merge(options)
            grant_logging_access_to_target_bucket(options['target_bucket'])
            logging_status(name, Status.new(options))
          end
          alias_method :enable_logging, :enable_logging_for
          
          # Disables logging for the bucket named <tt>name</tt>.
          def disable_logging_for(name = nil)
            logging_status(bucket_name(name), Status.new)
          end
          alias_method :disable_logging, :disable_logging_for
          
          # Returns true if logging has been enabled for the bucket named <tt>name</tt>.
          def logging_enabled_for?(name = nil)
            logging_status(bucket_name(name)).logging_enabled?
          end
          alias_method :logging_enabled?, :logging_enabled_for?
          
          # Returns the collection of logs for the bucket named <tt>name</tt>.
          #
          #   Bucket.logs_for 'marcel'
          #
          # Accepts the same options as Bucket.find, such as <tt>:max_keys</tt> and <tt>:marker</tt>.
          def logs_for(name = nil, options = {})
            if name.is_a?(Hash)
              options = name
              name    = nil
            end
            
            name           = bucket_name(name)
            logging_status = logging_status_for(name)
            return [] unless logging_status.logging_enabled?
            objects(logging_status.target_bucket, options.merge(:prefix => logging_status.target_prefix)).map do |log_object|
              Log.new(log_object)
            end
          end
          alias_method :logs, :logs_for
        end
        
        module LoggingGrants #:nodoc:
          def grant_logging_access_to_target_bucket(target_bucket)
            acl = acl(target_bucket)
            acl.grants << ACL::Grant.grant(:logging_write)
            acl.grants << ACL::Grant.grant(:logging_read_acp)
            acl(target_bucket, acl)
          end
        end
        
        def logging_status
          self.class.logging_status_for(name)
        end
        
        def enable_logging(*args)
          self.class.enable_logging_for(name, *args)
        end
        
        def disable_logging(*args)
          self.class.disable_logging_for(name, *args)
        end
        
        def logging_enabled?
          self.class.logging_enabled_for?(name)
        end
        
        def logs(options = {})
          self.class.logs_for(name, options)
        end
      end
    end
  end
end