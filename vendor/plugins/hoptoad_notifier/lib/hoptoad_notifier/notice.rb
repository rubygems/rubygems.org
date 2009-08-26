module HoptoadNotifier
  class Notice

    # The exception that caused this notice, if any
    attr_reader :exception

    # The API key for the project to which this notice should be sent
    attr_reader :api_key

    # The backtrace from the given exception or hash.
    attr_reader :backtrace

    # The name of the class of error (such as RuntimeError)
    attr_reader :error_class

    # The server environment variables at the time of the error
    attr_reader :environment_vars

    # The name of the server environment (such as "production")
    attr_reader :environment_name

    # CGI variables such as HTTP_METHOD
    attr_reader :cgi_data

    # The message from the exception, or a general description of the error
    attr_reader :error_message

    # See Configuration#backtrace_filters
    attr_reader :backtrace_filters

    # See Configuration#params_filters
    attr_reader :params_filters

    # See Configuration#environment_filters
    attr_reader :environment_filters

    # A hash of parameters from the query string or post body.
    attr_reader :parameters
    alias_method :params, :parameters

    # The controller (if any) which was used in this request
    attr_reader :controller

    # The action (if any) that was called in this request
    attr_reader :action

    # A hash of session data from the request
    attr_reader :session_data

    # The path to the project that caused the error (usually RAILS_ROOT)
    attr_reader :project_root

    # The URL at which the error occurred (if any)
    attr_reader :url

    # See Configuration#ignore
    attr_reader :ignore

    # See Configuration#ignore_by_filters
    attr_reader :ignore_by_filters

    # The name of the notifier library sending this notice, such as "Hoptoad Notifier"
    attr_reader :notifier_name

    # The version number of the notifier library sending this notice, such as "2.1.3"
    attr_reader :notifier_version

    # A URL for more information about the notifier library sending this notice
    attr_reader :notifier_url

    def initialize(args)
      self.args         = args
      self.exception    = args[:exception]
      self.api_key      = args[:api_key]
      self.project_root = args[:project_root]
      self.url          = args[:url]

      self.notifier_name    = args[:notifier_name]
      self.notifier_version = args[:notifier_version]
      self.notifier_url     = args[:notifier_url]

      self.ignore              = args[:ignore]              || []
      self.ignore_by_filters   = args[:ignore_by_filters]   || []
      self.backtrace_filters   = args[:backtrace_filters]   || []
      self.params_filters      = args[:params_filters]      || []
      self.environment_filters = args[:environment_filters] || []
      self.parameters          = args[:parameters]          || {}
      self.controller          = args[:controller]
      self.action              = args[:action]

      self.environment_vars = args[:environment_vars] || ENV.to_hash
      self.environment_name = args[:environment_name]
      self.cgi_data         = args[:cgi_data]
      self.backtrace        = Backtrace.parse(exception_attribute(:backtrace, caller))
      self.error_class      = exception_attribute(:error_class) {|exception| exception.class.name }
      self.error_message    = exception_attribute(:error_message, 'Notification') do |exception|
        "#{exception.class.name}: #{exception.message}"
      end

      find_session_data
      clean_params
      clean_environment
    end

    # Converts the given notice to XML
    def to_xml
      builder = Builder::XmlMarkup.new
      builder.instruct!
      xml = builder.notice(:version => HoptoadNotifier::VERSION) do |notice|
        notice.tag!("api-key", api_key)
        notice.notifier do |notifier|
          notifier.name(notifier_name)
          notifier.version(notifier_version)
          notifier.url(notifier_url)
        end
        notice.error do |error|
          error.class(error_class)
          error.message(error_message)
          error.backtrace do |backtrace|
            self.backtrace.lines.each do |line|
              backtrace.line(:number => line.number,
                             :file   => line.file,
                             :method => line.method)
            end
          end
        end
        notice.request do |request|
          request.url(url)
          request.controller(controller)
          request.action(action)
          unless parameters.blank?
            request.params do |params|
              xml_vars_for(params, parameters)
            end
          end
          unless session_data.blank?
            request.session do |session|
              xml_vars_for(session, session_data)
            end
          end
          unless cgi_data.blank?
            request.tag!("cgi-data") do |cgi_datum|
              xml_vars_for(cgi_datum, cgi_data)
            end
          end
        end
        notice.tag!("server-environment") do |env|
          env.tag!("project-root", project_root)
          env.tag!("environment-name", environment_name)
          xml_vars_for(env, environment_vars)
        end
      end
      xml.to_s
    end

    # Determines if this notice should be ignored
    def ignore?
      ignored_class_names.include?(error_class) ||
        ignore_by_filters.any? {|filter| filter.call(self) }
    end

    # Allows properties to be accessed using a hash-like syntax
    #
    # @example
    #   notice[:error_message]
    # @param [String] method The given key for an attribute
    # @return The attribute value, or self if given +:request+
    def [](method)
      case method
      when :request
        self
      else
        send(method)
      end
    end

    private

    attr_writer :exception, :api_key, :backtrace, :error_class, :error_message,
      :environment_vars, :backtrace_filters, :parameters, :params_filters,
      :environment_filters, :session_data, :project_root, :url, :ignore,
      :ignore_by_filters, :notifier_name, :notifier_url, :notifier_version,
      :controller, :action, :cgi_data, :environment_name

    # Arguments given in the initializer
    attr_accessor :args

    # Gets a property named +attribute+ of an exception, either from an actual
    # exception or a hash.
    #
    # If an exception is available, #from_exception will be used. Otherwise,
    # a key named +attribute+ will be used from the #args.
    #
    # If no exception or hash key is available, +default+ will be used.
    def exception_attribute(attribute, default = nil, &block)
      if exception
        from_exception(attribute, &block)
      else
        args[attribute] || default
      end
    end

    # Gets a property named +attribute+ from an exception.
    #
    # If a block is given, it will be used when getting the property from an
    # exception. The block should accept and exception and return the value for
    # the property.
    #
    # If no block is given, a method with the same name as +attribute+ will be
    # invoked for the value.
    def from_exception(attribute)
      if block_given?
        yield(exception)
      else
        exception.send(attribute)
      end
    end

    # Removes non-serializable data from the given attribute.
    # See #clean_unserializable_data
    def clean_unserializable_data_from(attribute)
      self.send(:"#{attribute}=", clean_unserializable_data(send(attribute)))
    end

    # Removes non-serializable data. Allowed data types are strings, arrays,
    # and hashes. All other types are converted to strings.
    # TODO: move this onto Hash
    def clean_unserializable_data(data)
      if data.respond_to?(:to_hash)
        data.inject({}) do |result, (key, value)|
          result.merge(key => clean_unserializable_data(value))
        end
      elsif data.respond_to?(:to_ary)
        data.collect do |value|
          clean_unserializable_data(value)
        end
      else
        data.to_s
      end
    end

    # Replaces the contents of params that match params_filters.
    # TODO: extract this to a different class
    def clean_params
      clean_unserializable_data_from(:parameters)
      if params_filters
        parameters.keys.each do |key|
          parameters[key] = "[FILTERED]" if params_filters.any? do |filter|
            key.to_s.include?(filter)
          end
        end
      end
    end

    # Replaces the contents of params that match params_filters.
    # TODO: extract this to a different class
    def clean_environment
      clean_unserializable_data_from(:environment_vars)
      if environment_filters
        environment_vars.keys.each do |key|
          environment_vars[key] = "[FILTERED]" if environment_filters.any? do |filter|
            key.to_s.include?(filter)
          end
        end
      end
    end

    def find_session_data
      self.session_data = args[:session_data] || args[:session] || {}
      self.session_data = session_data[:data] if session_data[:data]
    end

    # Converts the mixed class instances and class names into just names
    # TODO: move this into Configuration or another class
    def ignored_class_names
      ignore.collect do |string_or_class|
        if string_or_class.respond_to?(:name)
          string_or_class.name
        else
          string_or_class
        end
      end
    end

    def xml_vars_for(builder, hash)
      hash.each do |key, value|
        if value.is_a?(Hash)
          builder.var(:key => key){|b| xml_vars_for(b, value) }
        else
          builder.var(value.to_s, :key => key)
        end
      end
    end
  end
end
