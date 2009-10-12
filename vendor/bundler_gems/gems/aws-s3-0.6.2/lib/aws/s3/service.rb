module AWS
  module S3
    # The service lets you find out general information about your account, like what buckets you have. 
    # 
    #   Service.buckets
    #   # => []
    class Service < Base
      @@response = nil #:nodoc:
      
      class << self
        # List all your buckets.
        #
        #   Service.buckets
        #   # => []
        #
        # For performance reasons, the bucket list will be cached. If you want avoid all caching, pass the <tt>:reload</tt> 
        # as an argument:
        #
        #   Service.buckets(:reload)
        def buckets
          response = get('/')
          if response.empty?
            []
          else
            response.buckets.map {|attributes| Bucket.new(attributes)}
          end
        end
        memoized :buckets
        
        # Sometimes methods that make requests to the S3 servers return some object, like a Bucket or an S3Object. 
        # Othertimes they return just <tt>true</tt>. Other times they raise an exception that you may want to rescue. Despite all these 
        # possible outcomes, every method that makes a request stores its response object for you in Service.response. You can always 
        # get to the last request's response via Service.response.
        # 
        #   objects = Bucket.objects('jukebox')
        #   Service.response.success?
        #   # => true
        #
        # This is also useful when an error exception is raised in the console which you weren't expecting. You can 
        # root around in the response to get more details of what might have gone wrong.
        def response
          @@response
        end
        
        def response=(response) #:nodoc:
          @@response = response
        end
      end
    end
  end
end