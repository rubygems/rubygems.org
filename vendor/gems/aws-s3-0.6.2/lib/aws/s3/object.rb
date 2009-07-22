module AWS
  module S3
    # S3Objects represent the data you store on S3. They have a key (their name) and a value (their data). All objects belong to a
    # bucket.
    #
    # You can store an object on S3 by specifying a key, its data and the name of the bucket you want to put it in:
    #
    #   S3Object.store('me.jpg', open('headshot.jpg'), 'photos')
    #
    # The content type of the object will be inferred by its extension. If the appropriate content type can not be inferred, S3 defaults
    # to <tt>binary/octet-stream</tt>.
    #
    # If you want to override this, you can explicitly indicate what content type the object should have with the <tt>:content_type</tt> option:
    # 
    #   file = 'black-flowers.m4a'
    #   S3Object.store(
    #     file,
    #     open(file),
    #     'jukebox',
    #     :content_type => 'audio/mp4a-latm'
    #   )
    #
    # You can read more about storing files on S3 in the documentation for S3Object.store.
    #
    # If you just want to fetch an object you've stored on S3, you just specify its name and its bucket:
    #
    #   picture = S3Object.find 'headshot.jpg', 'photos'
    #
    # N.B. The actual data for the file is not downloaded in both the example where the file appeared in the bucket and when fetched directly. 
    # You get the data for the file like this:
    # 
    #   picture.value
    #
    # You can fetch just the object's data directly:
    #
    #   S3Object.value 'headshot.jpg', 'photos'
    #
    # Or stream it by passing a block to <tt>stream</tt>:
    # 
    #   open('song.mp3', 'w') do |file|
    #     S3Object.stream('song.mp3', 'jukebox') do |chunk|
    #       file.write chunk
    #     end
    #   end
    #
    # The data of the file, once download, is cached, so subsequent calls to <tt>value</tt> won't redownload the file unless you 
    # tell the object to reload its <tt>value</tt>:
    # 
    #   # Redownloads the file's data
    #   song.value(:reload) 
    #
    # Other functionality includes:
    #
    #   # Check if an object exists?
    #   S3Object.exists? 'headshot.jpg', 'photos'
    #
    #   # Copying an object
    #   S3Object.copy 'headshot.jpg', 'headshot2.jpg', 'photos'
    #
    #   # Renaming an object
    #   S3Object.rename 'headshot.jpg', 'portrait.jpg', 'photos'
    #
    #   # Deleting an object
    #   S3Object.delete 'headshot.jpg', 'photos'
    # 
    # ==== More about objects and their metadata
    # 
    # You can find out the content type of your object with the <tt>content_type</tt> method:
    # 
    #   song.content_type
    #   # => "audio/mpeg"
    # 
    # You can change the content type as well if you like:
    # 
    #   song.content_type = 'application/pdf'
    #   song.store
    # 
    # (Keep in mind that due to limitiations in S3's exposed API, the only way to change things like the content_type
    # is to PUT the object onto S3 again. In the case of large files, this will result in fully re-uploading the file.)
    # 
    # A bevie of information about an object can be had using the <tt>about</tt> method:
    # 
    #   pp song.about
    #   {"last-modified"    => "Sat, 28 Oct 2006 21:29:26 GMT",
    #    "content-type"     => "binary/octet-stream",
    #    "etag"             => "\"dc629038ffc674bee6f62eb64ff3a\"",
    #    "date"             => "Sat, 28 Oct 2006 21:30:41 GMT",
    #    "x-amz-request-id" => "B7BC68F55495B1C8",
    #    "server"           => "AmazonS3",
    #    "content-length"   => "3418766"}
    # 
    # You can get and set metadata for an object:
    # 
    #   song.metadata
    #   # => {}
    #   song.metadata[:album] = "A River Ain't Too Much To Love"
    #   # => "A River Ain't Too Much To Love"
    #   song.metadata[:released] = 2005
    #   pp song.metadata
    #   {"x-amz-meta-released" => 2005, 
    #     "x-amz-meta-album"   => "A River Ain't Too Much To Love"}
    #   song.store
    # 
    # That metadata will be saved in S3 and is hence forth available from that object:
    # 
    #   song = S3Object.find('black-flowers.mp3', 'jukebox')
    #   pp song.metadata
    #   {"x-amz-meta-released" => "2005", 
    #     "x-amz-meta-album"   => "A River Ain't Too Much To Love"}
    #   song.metadata[:released]
    #   # => "2005"
    #   song.metadata[:released] = 2006
    #   pp song.metadata
    #   {"x-amz-meta-released" => 2006, 
    #    "x-amz-meta-album"    => "A River Ain't Too Much To Love"}
    class S3Object < Base
      class << self        
        # Returns the value of the object with <tt>key</tt> in the specified bucket.
        #
        # === Conditional GET options
        #
        # * <tt>:if_modified_since</tt> - Return the object only if it has been modified since the specified time, 
        #   otherwise return a 304 (not modified).
        # * <tt>:if_unmodified_since</tt> - Return the object only if it has not been modified since the specified time, 
        #   otherwise raise PreconditionFailed.
        # * <tt>:if_match</tt> - Return the object only if its entity tag (ETag) is the same as the one specified, 
        #   otherwise raise PreconditionFailed.
        # * <tt>:if_none_match</tt> - Return the object only if its entity tag (ETag) is different from the one specified, 
        #   otherwise return a 304 (not modified).
        #
        # === Other options
        # * <tt>:range</tt> - Return only the bytes of the object in the specified range.
        def value(key, bucket = nil, options = {}, &block)
          Value.new(get(path!(bucket, key, options), options, &block))
        end
        
        def stream(key, bucket = nil, options = {}, &block)
          value(key, bucket, options) do |response|
            response.read_body(&block)
          end
        end
        
        # Returns the object whose key is <tt>name</tt> in the specified bucket. If the specified key does not
        # exist, a NoSuchKey exception will be raised.
        def find(key, bucket = nil)
          # N.B. This is arguably a hack. From what the current S3 API exposes, when you retrieve a bucket, it
          # provides a listing of all the files in that bucket (assuming you haven't limited the scope of what it returns).
          # Each file in the listing contains information about that file. It is from this information that an S3Object is built.
          #
          # If you know the specific file that you want, S3 allows you to make a get request for that specific file and it returns
          # the value of that file in its response body. This response body is used to build an S3Object::Value object. 
          # If you want information about that file, you can make a head request and the headers of the response will contain 
          # information about that file. There is no way, though, to say, give me the representation of just this given file the same 
          # way that it would appear in a bucket listing.
          #
          # When fetching a bucket, you can provide options which narrow the scope of what files should be returned in that listing.
          # Of those options, one is <tt>marker</tt> which is a string and instructs the bucket to return only object's who's key comes after
          # the specified marker according to alphabetic order. Another option is <tt>max-keys</tt> which defaults to 1000 but allows you
          # to dictate how many objects should be returned in the listing. With a combination of <tt>marker</tt> and <tt>max-keys</tt> you can
          # *almost* specify exactly which file you'd like it to return, but <tt>marker</tt> is not inclusive. In other words, if there is a bucket
          # which contains three objects who's keys are respectively 'a', 'b' and 'c', then fetching a bucket listing with marker set to 'b' will only
          # return 'c', not 'b'. 
          #
          # Given all that, my hack to fetch a bucket with only one specific file, is to set the marker to the result of calling String#previous on
          # the desired object's key, which functionally makes the key ordered one degree higher than the desired object key according to 
          # alphabetic ordering. This is a hack, but it should work around 99% of the time. I can't think of a scenario where it would return
          # something incorrect.
          
          # We need to ensure the key doesn't have extended characters but not uri escape it before doing the lookup and comparing since if the object exists, 
          # the key on S3 will have been normalized
          key    = key.remove_extended unless key.valid_utf8?
          bucket = Bucket.find(bucket_name(bucket), :marker => key.previous, :max_keys => 1)
          # If our heuristic failed, trigger a NoSuchKey exception
          if (object = bucket.objects.first) && object.key == key
            object 
          else 
            raise NoSuchKey.new("No such key `#{key}'", bucket)
          end
        end
        
        # Makes a copy of the object with <tt>key</tt> to <tt>copy_key</tt>, preserving the ACL of the existing object if the <tt>:copy_acl</tt> option is true (default false).
        def copy(key, copy_key, bucket = nil, options = {})
          bucket          = bucket_name(bucket)
          source_key      = path!(bucket, key)
          default_options = {'x-amz-copy-source' => source_key}
          target_key      = path!(bucket, copy_key)
          returning put(target_key, default_options) do
            acl(copy_key, bucket, acl(key, bucket)) if options[:copy_acl]
          end
        end
        
        # Rename the object with key <tt>from</tt> to have key in <tt>to</tt>.
        def rename(from, to, bucket = nil, options = {})
          copy(from, to, bucket, options)
          delete(from, bucket)
        end
        
        # Fetch information about the object with <tt>key</tt> from <tt>bucket</tt>. Information includes content type, content length,
        # last modified time, and others.
        #
        # If the specified key does not exist, NoSuchKey is raised.
        def about(key, bucket = nil, options = {})
          response = head(path!(bucket, key, options), options)
          raise NoSuchKey.new("No such key `#{key}'", bucket) if response.code == 404
          About.new(response.headers)
        end
        
        # Checks if the object with <tt>key</tt> in <tt>bucket</tt> exists.
        #
        #   S3Object.exists? 'kiss.jpg', 'marcel'
        #   # => true
        def exists?(key, bucket = nil)
          about(key, bucket)
          true
        rescue NoSuchKey
          false
        end
      
        # Delete object with <tt>key</tt> from <tt>bucket</tt>.
        def delete(key, bucket = nil, options = {})
          # A bit confusing. Calling super actually makes an HTTP DELETE request. The delete method is
          # defined in the Base class. It happens to have the same name.
          super(path!(bucket, key, options), options).success?
        end
        
        # When storing an object on the S3 servers using S3Object.store, the <tt>data</tt> argument can be a string or an I/O stream. 
        # If <tt>data</tt> is an I/O stream it will be read in segments and written to the socket incrementally. This approach 
        # may be desirable for very large files so they are not read into memory all at once.
        # 
        #   # Non streamed upload
        #   S3Object.store('greeting.txt', 'hello world!', 'marcel')
        #
        #   # Streamed upload
        #   S3Object.store('roots.mpeg', open('roots.mpeg'), 'marcel')
        def store(key, data, bucket = nil, options = {})
          validate_key!(key)
          # Must build path before infering content type in case bucket is being used for options
          path = path!(bucket, key, options)
          infer_content_type!(key, options)
          
          put(path, options, data) # Don't call .success? on response. We want to get the etag.
        end
        alias_method :create, :store
        alias_method :save,   :store
        
        # All private objects are accessible via an authenticated GET request to the S3 servers. You can generate an 
        # authenticated url for an object like this:
        #
        #   S3Object.url_for('beluga_baby.jpg', 'marcel_molina')
        #
        # By default authenticated urls expire 5 minutes after they were generated.
        #
        # Expiration options can be specified either with an absolute time since the epoch with the <tt>:expires</tt> options,
        # or with a number of seconds relative to now with the <tt>:expires_in</tt> options:
        #
        #   # Absolute expiration date 
        #   # (Expires January 18th, 2038)
        #   doomsday = Time.mktime(2038, 1, 18).to_i
        #   S3Object.url_for('beluga_baby.jpg', 
        #                    'marcel', 
        #                    :expires => doomsday)
        #   
        #   # Expiration relative to now specified in seconds 
        #   # (Expires in 3 hours)
        #   S3Object.url_for('beluga_baby.jpg', 
        #                    'marcel', 
        #                    :expires_in => 60 * 60 * 3)
        #
        # You can specify whether the url should go over SSL with the <tt>:use_ssl</tt> option:
        #
        #   # Url will use https protocol
        #   S3Object.url_for('beluga_baby.jpg', 
        #                    'marcel', 
        #                    :use_ssl => true)
        #
        # By default, the ssl settings for the current connection will be used.
        #
        # If you have an object handy, you can use its <tt>url</tt> method with the same objects:
        #
        #   song.url(:expires_in => 30)
        #
        # To get an unauthenticated url for the object, such as in the case
        # when the object is publicly readable, pass the
        # <tt>:authenticated</tt> option with a value of <tt>false</tt>.
        #
        #   S3Object.url_for('beluga_baby.jpg',
        #                    'marcel',
        #                    :authenticated => false)
        #   # => http://s3.amazonaws.com/marcel/beluga_baby.jpg
        def url_for(name, bucket = nil, options = {})
          connection.url_for(path!(bucket, name, options), options) # Do not normalize options
        end
        
        def path!(bucket, name, options = {}) #:nodoc:
          # We're using the second argument for options
          if bucket.is_a?(Hash)
            options.replace(bucket)
            bucket = nil
          end
          '/' << File.join(bucket_name(bucket), name)
        end
    
        private
          
          def validate_key!(key)
            raise InvalidKeyName.new(key) unless key && key.size <= 1024
          end
          
          def infer_content_type!(key, options)
            return if options.has_key?(:content_type)
            if mime_type = MIME::Types.type_for(key).first
              options[:content_type] = mime_type.content_type
            end
          end
      end
      
      class Value < String #:nodoc:
        attr_reader :response
        def initialize(response)
          super(response.body)
          @response = response
        end
      end
      
      class About < Hash #:nodoc:
        def initialize(headers)
          super()
          replace(headers)
          metadata
        end
        
        def [](header)
          super(header.to_header)
        end
        
        def []=(header, value)
          super(header.to_header, value)
        end
        
        def to_headers
          self.merge(metadata.to_headers)
        end
          
        def metadata
          Metadata.new(self)
        end
        memoized :metadata
      end
      
      class Metadata < Hash #:nodoc:
        HEADER_PREFIX = 'x-amz-meta-'
        SIZE_LIMIT    = 2048 # 2 kilobytes
        
        def initialize(headers)
          @headers = headers
          super()
          extract_metadata!
        end
        
        def []=(header, value)
          super(header_name(header.to_header), value)
        end
        
        def [](header)
          super(header_name(header.to_header))
        end
        
        def to_headers
          validate!
          self
        end
        
        private
          attr_reader :headers
          
          def extract_metadata!
            headers.keys.grep(Regexp.new(HEADER_PREFIX)).each do |metadata_header|
              self[metadata_header] = headers.delete(metadata_header)
            end
          end
          
          def header_name(name)
            name =~ Regexp.new(HEADER_PREFIX) ? name : [HEADER_PREFIX, name].join
          end
          
          def validate!
            invalid_headers = inject([]) do |invalid, (name, value)|
              invalid << name unless valid?(value)
              invalid
            end
            
            raise InvalidMetadataValue.new(invalid_headers) unless invalid_headers.empty?
          end
          
          def valid?(value)
            value && value.size < SIZE_LIMIT
          end
      end
      
      attr_writer :value #:nodoc:
      
      # Provides readers and writers for all valid header settings listed in <tt>valid_header_settings</tt>.
      # Subsequent saves to the object after setting any of the valid headers settings will be reflected in 
      # information about the object.
      #
      #   some_s3_object.content_type
      #   => nil
      #   some_s3_object.content_type = 'text/plain'
      #   => "text/plain"
      #   some_s3_object.content_type
      #   => "text/plain"
      #   some_s3_object.store
      #   S3Object.about(some_s3_object.key, some_s3_object.bucket.name)['content-type']
      #   => "text/plain"
      include SelectiveAttributeProxy #:nodoc
      
      proxy_to :about, :exclusively => false
      
      # Initializes a new S3Object.
      def initialize(attributes = {}, &block)
        super
        self.value  = attributes.delete(:value) 
        self.bucket = attributes.delete(:bucket)
        yield self if block_given?
      end
      
      # The current object's bucket. If no bucket has been set, a NoBucketSpecified exception will be raised. For
      # cases where you are not sure if the bucket has been set, you can use the belongs_to_bucket? method.
      def bucket
        @bucket or raise NoBucketSpecified
      end
      
      # Sets the bucket that the object belongs to.
      def bucket=(bucket)
        @bucket = bucket
        self
      end
      
      # Returns true if the current object has been assigned to a bucket yet. Objects must belong to a bucket before they
      # can be saved onto S3.
      def belongs_to_bucket?
        !@bucket.nil?
      end
      alias_method :orphan?, :belongs_to_bucket?
      
      # Returns the key of the object. If the key is not set, a NoKeySpecified exception will be raised. For cases
      # where you are not sure if the key has been set, you can use the key_set? method. Objects must have a key
      # set to be saved onto S3. Objects which have already been saved onto S3 will always have their key set.
      def key
        attributes['key'] or raise NoKeySpecified
      end
      
      # Sets the key for the current object.
      def key=(value)
        attributes['key'] = value
      end
      
      # Returns true if the current object has had its key set yet. Objects which have already been saved will
      # always return true. This method is useful for objects which have not been saved yet so you know if you
      # need to set the object's key since you can not save an object unless its key has been set.
      #
      #   object.store if object.key_set? && object.belongs_to_bucket?
      def key_set?
        !attributes['key'].nil?
      end
      
      # Lazily loads object data. 
      #
      # Force a reload of the data by passing <tt>:reload</tt>.
      #
      #   object.value(:reload)
      #
      # When loading the data for the first time you can optionally yield to a block which will
      # allow you to stream the data in segments.
      #
      #   object.value do |segment|
      #     send_data segment
      #   end 
      #
      # The full list of options are listed in the documentation for its class method counter part, S3Object::value.
      def value(options = {}, &block)
        if options.is_a?(Hash)
          reload = !options.empty?
        else
          reload  = options
          options = {}
        end
        expirable_memoize(reload) do
          self.class.stream(key, bucket.name, options, &block)
        end
      end
      
      # Interface to information about the current object. Information is read only, though some of its data
      # can be modified through specific methods, such as content_type and content_type=.
      #
      #   pp some_object.about
      #     {"last-modified"    => "Sat, 28 Oct 2006 21:29:26 GMT",
      #      "x-amz-id-2"       =>  "LdcQRk5qLwxJQiZ8OH50HhoyKuqyWoJ67B6i+rOE5MxpjJTWh1kCkL+I0NQzbVQn",
      #      "content-type"     => "binary/octet-stream",
      #      "etag"             => "\"dc629038ffc674bee6f62eb68454ff3a\"",
      #      "date"             => "Sat, 28 Oct 2006 21:30:41 GMT",
      #      "x-amz-request-id" => "B7BC68F55495B1C8",
      #      "server"           => "AmazonS3",
      #      "content-length"   => "3418766"}
      #
      #  some_object.content_type
      #  # => "binary/octet-stream"
      #  some_object.content_type = 'audio/mpeg'
      #  some_object.content_type
      #  # => 'audio/mpeg'
      #  some_object.store
      def about
        stored? ? self.class.about(key, bucket.name) : About.new
      end
      memoized :about
      
      # Interface to viewing and editing metadata for the current object. To be treated like a Hash.
      #
      #   some_object.metadata
      #   # => {}
      #   some_object.metadata[:author] = 'Dave Thomas'
      #   some_object.metadata
      #   # => {"x-amz-meta-author" => "Dave Thomas"}
      #   some_object.metadata[:author]
      #   # => "Dave Thomas"
      def metadata
        about.metadata
      end
      memoized :metadata
      
      # Saves the current object with the specified <tt>options</tt>. Valid options are listed in the documentation for S3Object::store.
      def store(options = {})
        raise DeletedObject if frozen?
        options  = about.to_headers.merge(options) if stored?
        response = self.class.store(key, value, bucket.name, options)
        bucket.update(:stored, self)
        response.success?
      end
      alias_method :create, :store
      alias_method :save,   :store
      
      # Deletes the current object. Trying to save an object after it has been deleted with
      # raise a DeletedObject exception.
      def delete
        bucket.update(:deleted, self)
        freeze
        self.class.delete(key, bucket.name)
      end
      
      # Copies the current object, given it the name <tt>copy_name</tt>. Keep in mind that due to limitations in 
      # S3's API, this operation requires retransmitting the entire object to S3.
      def copy(copy_name, options = {})
        self.class.copy(key, copy_name, bucket.name, options)
      end
      
      # Rename the current object. Keep in mind that due to limitations in S3's API, this operation requires
      # retransmitting the entire object to S3.
      def rename(to, options = {})
        self.class.rename(key, to, bucket.name, options)
      end
      
      def etag(reload = false)
        return nil unless stored?
        expirable_memoize(reload) do
          reload ? about(reload)['etag'][1...-1] : attributes['e_tag'][1...-1]
        end
      end
      
      # Returns the owner of the current object.
      def owner 
        Owner.new(attributes['owner'])
      end
      memoized :owner
      
      # Generates an authenticated url for the current object. Accepts the same options as its class method
      # counter part S3Object.url_for.
      def url(options = {})
        self.class.url_for(key, bucket.name, options)
      end
      
      # Returns true if the current object has been stored on S3 yet.
      def stored?
        !attributes['e_tag'].nil?
      end
      
      def ==(s3object) #:nodoc:
        path == s3object.path
      end
      
      def path #:nodoc:
        self.class.path!(
          belongs_to_bucket? ? bucket.name : '(no bucket)', 
          key_set?           ? key         : '(no key)'
        )
      end
        
      # Don't dump binary data :)
      def inspect #:nodoc:
        "#<%s:0x%s '%s'>" % [self.class, object_id, path]
      end
      
      private
        def proxiable_attribute?(name)
          valid_header_settings.include?(name)
        end
        
        def valid_header_settings
          %w(cache_control content_type content_length content_md5 content_disposition content_encoding expires)
        end
    end
  end
end
