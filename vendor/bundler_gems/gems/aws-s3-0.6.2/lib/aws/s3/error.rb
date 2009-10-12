module AWS
  module S3
    # Anything you do that makes a request to S3 could result in an error. If it does, the AWS::S3 library will raise an exception 
    # specific to the error. All exception that are raised as a result of a request returning an error response inherit from the 
    # ResponseError exception. So should you choose to rescue any such exception, you can simple rescue ResponseError. 
    # 
    # Say you go to delete a bucket, but the bucket turns out to not be empty. This results in a BucketNotEmpty error (one of the many 
    # errors listed at http://docs.amazonwebservices.com/AmazonS3/2006-03-01/ErrorCodeList.html):
    # 
    #   begin
    #     Bucket.delete('jukebox')
    #   rescue ResponseError => error
    #     # ...
    #   end
    # 
    # Once you've captured the exception, you can extract the error message from S3, as well as the full error response, which includes 
    # things like the HTTP response code:
    # 
    #   error
    #   # => #<AWS::S3::BucketNotEmpty The bucket you tried to delete is not empty>
    #   error.message
    #   # => "The bucket you tried to delete is not empty"
    #   error.response.code
    #   # => 409
    # 
    # You could use this information to redisplay the error in a way you see fit, or just to log the error and continue on.
    class Error
      #:stopdoc:
      attr_accessor :response
      def initialize(error, response = nil)
        @error     = error
        @response  = response
        @container = AWS::S3
        find_or_create_exception!
      end
      
      def raise
        Kernel.raise exception.new(message, response)
      end
      
      private
        attr_reader :error, :exception, :container
        
        def find_or_create_exception!
          @exception = container.const_defined?(code) ? find_exception : create_exception
        end
        
        def find_exception
          exception_class = container.const_get(code)
          Kernel.raise ExceptionClassClash.new(exception_class) unless exception_class.ancestors.include?(ResponseError)
          exception_class
        end
        
        def create_exception
          container.const_set(code, Class.new(ResponseError))
        end
        
        def method_missing(method, *args, &block)
          # We actually want nil if the attribute is nil. So we use has_key? rather than [] + ||.
          if error.has_key?(method.to_s)
            error[method.to_s]
          else
            super
          end
        end
    end
  end
end
#:startdoc: