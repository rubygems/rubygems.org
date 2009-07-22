module AWS #:nodoc:
  # AWS::S3 is a Ruby library for Amazon's Simple Storage Service's REST API (http://aws.amazon.com/s3).
  # Full documentation of the currently supported API can be found at http://docs.amazonwebservices.com/AmazonS3/2006-03-01.
  # 
  # == Getting started
  # 
  # To get started you need to require 'aws/s3':
  # 
  #   % irb -rubygems
  #   irb(main):001:0> require 'aws/s3'
  #   # => true
  # 
  # The AWS::S3 library ships with an interactive shell called <tt>s3sh</tt>. From within it, you have access to all the operations the library exposes from the command line.
  # 
  #   % s3sh
  #   >> Version
  # 
  # Before you can do anything, you must establish a connection using Base.establish_connection!.  A basic connection would look something like this:
  # 
  #   AWS::S3::Base.establish_connection!(
  #     :access_key_id     => 'abc', 
  #     :secret_access_key => '123'
  #   )
  # 
  # The minimum connection options that you must specify are your access key id and your secret access key.
  # 
  # (If you don't already have your access keys, all you need to sign up for the S3 service is an account at Amazon. You can sign up for S3 and get access keys by visiting http://aws.amazon.com/s3.)
  # 
  # For convenience, if you set two special environment variables with the value of your access keys, the console will automatically create a default connection for you. For example:
  # 
  #   % cat .amazon_keys
  #   export AMAZON_ACCESS_KEY_ID='abcdefghijklmnop'
  #   export AMAZON_SECRET_ACCESS_KEY='1234567891012345'
  # 
  # Then load it in your shell's rc file.
  # 
  #   % cat .zshrc
  #   if [[ -f "$HOME/.amazon_keys" ]]; then
  #     source "$HOME/.amazon_keys";
  #   fi
  # 
  # See more connection details at AWS::S3::Connection::Management::ClassMethods.
  module S3
    constant :DEFAULT_HOST, 's3.amazonaws.com'
    
    # AWS::S3::Base is the abstract super class of all classes who make requests against S3, such as the built in
    # Service, Bucket and S3Object classes. It provides methods for making requests, inferring or setting response classes,
    # processing request options, and accessing attributes from S3's response data.
    #
    # Establishing a connection with the Base class is the entry point to using the library:
    #
    #   AWS::S3::Base.establish_connection!(:access_key_id => '...', :secret_access_key => '...')
    #
    # The <tt>:access_key_id</tt> and <tt>:secret_access_key</tt> are the two required connection options. More 
    # details can be found in the docs for Connection::Management::ClassMethods.
    #
    # Extensive examples can be found in the README[link:files/README.html].
    class Base      
      class << self
        # Wraps the current connection's request method and picks the appropriate response class to wrap the response in.
        # If the response is an error, it will raise that error as an exception. All such exceptions can be caught by rescuing
        # their superclass, the ResponseError exception class.
        #
        # It is unlikely that you would call this method directly. Subclasses of Base have convenience methods for each http request verb
        # that wrap calls to request.
        def request(verb, path, options = {}, body = nil, attempts = 0, &block)
          Service.response = nil
          process_options!(options, verb)
          response = response_class.new(connection.request(verb, path, options, body, attempts, &block))
          Service.response = response

          Error::Response.new(response.response).error.raise if response.error?
          response
        # Once in a while, a request to S3 returns an internal error. A glitch in the matrix I presume. Since these 
        # errors are few and far between the request method will rescue InternalErrors the first three times they encouter them
        # and will retry the request again. Most of the time the second attempt will work.
        rescue InternalError, RequestTimeout
          if attempts == 3
            raise
          else
            attempts += 1
            retry
          end
        end

        [:get, :post, :put, :delete, :head].each do |verb|
          class_eval(<<-EVAL, __FILE__, __LINE__)
            def #{verb}(path, headers = {}, body = nil, &block)
              request(:#{verb}, path, headers, body, &block)
            end
          EVAL
        end
        
        # Called when a method which requires a bucket name is called without that bucket name specified. It will try to
        # infer the current bucket by looking for it as the subdomain of the current connection's address. If no subdomain
        # is found, CurrentBucketNotSpecified will be raised.
        #
        #   MusicBucket.establish_connection! :server => 'jukeboxzero.s3.amazonaws.com'
        #   MusicBucket.connection.server
        #   => 'jukeboxzero.s3.amazonaws.com'
        #   MusicBucket.current_bucket
        #   => 'jukeboxzero'
        #
        # Rather than infering the current bucket from the subdomain, the current class' bucket can be explicitly set with
        # set_current_bucket_to.
        def current_bucket
          connection.subdomain or raise CurrentBucketNotSpecified.new(connection.http.address)
        end
        
        # If you plan on always using a specific bucket for certain files, you can skip always having to specify the bucket by creating 
        # a subclass of Bucket or S3Object and telling it what bucket to use:
        # 
        #   class JukeBoxSong < AWS::S3::S3Object
        #     set_current_bucket_to 'jukebox'
        #   end
        # 
        # For all methods that take a bucket name as an argument, the current bucket will be used if the bucket name argument is omitted.
        #
        #   other_song = 'baby-please-come-home.mp3'
        #   JukeBoxSong.store(other_song, open(other_song))
        # 
        # This time we didn't have to explicitly pass in the bucket name, as the JukeBoxSong class knows that it will
        # always use the 'jukebox' bucket. 
        # 
        # "Astute readers", as they say, may have noticed that we used the third parameter to pass in the content type,
        # rather than the fourth parameter as we had the last time we created an object. If the bucket can be inferred, or
        # is explicitly set, as we've done in the JukeBoxSong class, then the third argument can be used to pass in
        # options.
        # 
        # Now all operations that would have required a bucket name no longer do.
        # 
        #   other_song = JukeBoxSong.find('baby-please-come-home.mp3')
        def set_current_bucket_to(name)
          raise ArgumentError, "`#{__method__}' must be called on a subclass of #{self.name}" if self == AWS::S3::Base
          instance_eval(<<-EVAL)
            def current_bucket
              '#{name}'
            end
          EVAL
        end
        alias_method :current_bucket=, :set_current_bucket_to
        
        private
          
          def response_class
            FindResponseClass.for(self)
          end
          
          def process_options!(options, verb)
            options.replace(RequestOptions.process(options, verb))
          end
          
          # Using the conventions layed out in the <tt>response_class</tt> works for more than 80% of the time.
          # There are a few edge cases though where we want a given class to wrap its responses in different
          # response classes depending on which method is being called.
          def respond_with(klass)
            eval(<<-EVAL, binding, __FILE__, __LINE__)
              def new_response_class
                #{klass}
              end

              class << self
                alias_method :old_response_class, :response_class
                alias_method :response_class, :new_response_class
              end
            EVAL

            yield
          ensure
            # Restore the original version
            eval(<<-EVAL, binding, __FILE__, __LINE__)
              class << self
                alias_method :response_class, :old_response_class
              end
            EVAL
          end
          
          def bucket_name(name)
            name || current_bucket
          end
          
          class RequestOptions < Hash #:nodoc:
            attr_reader :options, :verb
            
            class << self
              def process(*args, &block)
                new(*args, &block).process!
              end
            end
            
            def initialize(options, verb = :get)
              @options = options.to_normalized_options
              @verb    = verb
              super()
            end
            
            def process!
              set_access_controls! if verb == :put
              replace(options)
            end
            
            private 
              def set_access_controls!
                ACL::OptionProcessor.process!(options)
              end
          end
      end
      
      def initialize(attributes = {}) #:nodoc:
        @attributes = attributes
      end
      
      private
        attr_reader :attributes
        
        def connection
          self.class.connection
        end
        
        def http
          connection.http
        end
        
        def request(*args, &block)
          self.class.request(*args, &block)
        end
        
        def method_missing(method, *args, &block)
          case
          when attributes.has_key?(method.to_s) 
            attributes[method.to_s]
          when attributes.has_key?(method)
            attributes[method]
          else 
            super
          end
        end
    end
  end
end
