#:stopdoc:
module AWS
  module S3
    class Base
      class Response < String  
        attr_reader :response, :body, :parsed
        def initialize(response)
          @response = response
          @body     = response.body.to_s
          super(body)
        end
    
        def headers
          headers = {}
          response.each do |header, value|
            headers[header] = value
          end
          headers
        end
        memoized :headers
    
        def [](header)
          headers[header]
        end
    
        def each(&block)
          headers.each(&block)
        end
    
        def code
          response.code.to_i
        end
    
        {:success      => 200..299, :redirect     => 300..399,
         :client_error => 400..499, :server_error => 500..599}.each do |result, code_range|
          class_eval(<<-EVAL, __FILE__, __LINE__)
            def #{result}? 
              return false unless response
              (#{code_range}).include? code
            end
          EVAL
        end
    
        def error?
          !success? && response['content-type'] == 'application/xml' && parsed.root == 'error'
        end
    
        def error
          Error.new(parsed, self)
        end
        memoized :error
    
        def parsed
          # XmlSimple is picky about what kind of object it parses, so we pass in body rather than self
          Parsing::XmlParser.new(body)
        end
        memoized :parsed
    
        def inspect
          "#<%s:0x%s %s %s>" % [self.class, object_id, response.code, response.message]
        end
      end
    end
    
    class Bucket  
      class Response < Base::Response
        def bucket
          parsed
        end
      end
    end
  
    class S3Object
      class Response < Base::Response
        def etag
          headers['etag'][1...-1]
        end
      end
    end

    class Service
      class Response < Base::Response
        def empty?
          parsed['buckets'].nil?
        end
  
        def buckets
          parsed['buckets']['bucket'] || []
        end
      end
    end
    
    module ACL
      class Policy
        class Response < Base::Response
          alias_method :policy, :parsed
        end
      end
    end
    
    # Requests whose response code is between 300 and 599 and contain an <Error></Error> in their body
    # are wrapped in an Error::Response. This Error::Response contains an Error object which raises an exception
    # that corresponds to the error in the response body. The exception object contains the ErrorResponse, so
    # in all cases where a request happens, you can rescue ResponseError and have access to the ErrorResponse and
    # its Error object which contains information about the ResponseError.
    #
    #   begin
    #     Bucket.create(..)
    #   rescue ResponseError => exception
    #    exception.response
    #    # => <Error::Response>
    #    exception.response.error
    #    # => <Error>
    #   end
    class Error
      class Response < Base::Response
        def error? 
          true
        end
      
        def inspect
          "#<%s:0x%s %s %s: '%s'>" % [self.class.name, object_id, response.code, error.code, error.message]
        end
      end
    end

    # Guess response class name from current class name. If the guessed response class doesn't exist
    # do the same thing to the current class's parent class, up the inheritance heirarchy until either
    # a response class is found or until we get to the top of the heirarchy in which case we just use 
    # the the Base response class.
    #
    # Important: This implemantation assumes that the Base class has a corresponding Base::Response.
    class FindResponseClass #:nodoc:
      class << self
        def for(start)
          new(start).find
        end
      end
  
      def initialize(start)
        @container     = AWS::S3
        @current_class = start
      end
  
      def find
        self.current_class = current_class.superclass until response_class_found?            
        target.const_get(class_to_find)
      end
  
      private
        attr_reader :container
        attr_accessor :current_class
        
        def target
          container.const_get(current_name)
        end
        
        def target?
          container.const_defined?(current_name)
        end
        
        def response_class_found?
          target? && target.const_defined?(class_to_find)
        end
        
        def class_to_find
          :Response
        end
        
        def current_name
          truncate(current_class)
        end
        
        def truncate(klass)
          klass.name[/[^:]+$/]
        end
      end
  end
end
#:startdoc: