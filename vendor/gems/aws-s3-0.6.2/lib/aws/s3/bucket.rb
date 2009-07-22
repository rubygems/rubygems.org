module AWS
  module S3
    # Buckets are containers for objects (the files you store on S3). To create a new bucket you just specify its name.
    # 
    #   # Pick a unique name, or else you'll get an error 
    #   # if the name is already taken.
    #   Bucket.create('jukebox')
    # 
    # Bucket names must be unique across the entire S3 system, sort of like domain names across the internet. If you try
    # to create a bucket with a name that is already taken, you will get an error.
    #
    # Assuming the name you chose isn't already taken, your new bucket will now appear in the bucket list:
    # 
    #   Service.buckets
    #   # => [#<AWS::S3::Bucket @attributes={"name"=>"jukebox"}>]
    # 
    # Once you have succesfully created a bucket you can you can fetch it by name using Bucket.find.
    #
    #   music_bucket = Bucket.find('jukebox')
    #
    # The bucket that is returned will contain a listing of all the objects in the bucket.
    #
    #   music_bucket.objects.size
    #   # => 0
    #
    # If all you are interested in is the objects of the bucket, you can get to them directly using Bucket.objects.
    #
    #   Bucket.objects('jukebox').size
    #   # => 0
    #
    # By default all objects will be returned, though there are several options you can use to limit what is returned, such as
    # specifying that only objects whose name is after a certain place in the alphabet be returned, and etc. Details about these options can
    # be found in the documentation for Bucket.find.
    #
    # To add an object to a bucket you specify the name of the object, its value, and the bucket to put it in.
    # 
    #   file = 'black-flowers.mp3'
    #   S3Object.store(file, open(file), 'jukebox')
    #
    # You'll see your file has been added to it:
    # 
    #   music_bucket.objects
    #   # => [#<AWS::S3::S3Object '/jukebox/black-flowers.mp3'>]
    # 
    # You can treat your bucket like a hash and access objects by name:
    # 
    #   jukebox['black-flowers.mp3']
    #   # => #<AWS::S3::S3Object '/jukebox/black-flowers.mp3'>
    # 
    # In the event that you want to delete a bucket, you can use Bucket.delete.
    #
    #   Bucket.delete('jukebox')
    #
    # Keep in mind, like unix directories, you can not delete a bucket unless it is empty. Trying to delete a bucket
    # that contains objects will raise a BucketNotEmpty exception.
    #
    # Passing the :force => true option to delete will take care of deleting all the bucket's objects for you.
    #
    #   Bucket.delete('photos', :force => true)
    #   # => true
    class Bucket < Base
      class << self
        # Creates a bucket named <tt>name</tt>. 
        #
        #   Bucket.create('jukebox')
        #
        # Your bucket name must be unique across all of S3. If the name
        # you request has already been taken, you will get a 409 Conflict response, and a BucketAlreadyExists exception
        # will be raised.
        #
        # By default new buckets have their access level set to private. You can override this using the <tt>:access</tt> option.
        #
        #   Bucket.create('internet_drop_box', :access => :public_read_write)
        #
        # The full list of access levels that you can set on Bucket and S3Object creation are listed in the README[link:files/README.html] 
        # in the section called 'Setting access levels'.
        def create(name, options = {})
          validate_name!(name)
          put("/#{name}", options).success?
        end
        
        # Fetches the bucket named <tt>name</tt>. 
        #
        #   Bucket.find('jukebox')
        #
        # If a default bucket is inferable from the current connection's subdomain, or if set explicitly with Base.set_current_bucket, 
        # it will be used if no bucket is specified.
        #
        #   MusicBucket.current_bucket
        #   => 'jukebox'
        #   MusicBucket.find.name
        #   => 'jukebox'
        #
        # By default all objects contained in the bucket will be returned (sans their data) along with the bucket.
        # You can access your objects using the Bucket#objects method.
        #
        #   Bucket.find('jukebox').objects
        # 
        # There are several options which allow you to limit which objects are retrieved. The list of object filtering options
        # are listed in the documentation for Bucket.objects.
        def find(name = nil, options = {})
          new(get(path(name, options)).bucket)
        end
        
        # Return just the objects in the bucket named <tt>name</tt>.
        #
        # By default all objects of the named bucket will be returned. There are options, though, for filtering
        # which objects are returned.
        #
        # === Object filtering options
        # 
        # * <tt>:max_keys</tt> - The maximum number of keys you'd like to see in the response body. 
        #   The server may return fewer than this many keys, but will not return more.
        #
        #     Bucket.objects('jukebox').size
        #     # => 3
        #     Bucket.objects('jukebox', :max_keys => 1).size
        #     # => 1
        #
        # * <tt>:prefix</tt> - Restricts the response to only contain results that begin with the specified prefix.
        #
        #     Bucket.objects('jukebox')
        #     # => [<AWS::S3::S3Object '/jazz/miles.mp3'>, <AWS::S3::S3Object '/jazz/dolphy.mp3'>, <AWS::S3::S3Object '/classical/malher.mp3'>]
        #     Bucket.objects('jukebox', :prefix => 'classical')
        #     # => [<AWS::S3::S3Object '/classical/malher.mp3'>]
        #
        # * <tt>:marker</tt> - Marker specifies where in the result set to resume listing. It restricts the response 
        #   to only contain results that occur alphabetically _after_ the value of marker. To retrieve the next set of results, 
        #   use the last key from the current page of results as the marker in your next request.
        # 
        #     # Skip 'mahler'
        #     Bucket.objects('jukebox', :marker => 'mb')
        #     # => [<AWS::S3::S3Object '/jazz/miles.mp3'>]
        #
        # === Examples
        #
        #   # Return no more than 2 objects whose key's are listed alphabetically after the letter 'm'.
        #   Bucket.objects('jukebox', :marker => 'm', :max_keys => 2)
        #   # => [<AWS::S3::S3Object '/jazz/miles.mp3'>, <AWS::S3::S3Object '/classical/malher.mp3'>]
        #
        #   # Return no more than 2 objects whose key's are listed alphabetically after the letter 'm' and have the 'jazz' prefix.
        #   Bucket.objects('jukebox', :marker => 'm', :max_keys => 2, :prefix => 'jazz')
        #   # => [<AWS::S3::S3Object '/jazz/miles.mp3'>]
        def objects(name = nil, options = {})
          find(name, options).object_cache
        end
        
        # Deletes the bucket named <tt>name</tt>.
        #
        # All objects in the bucket must be deleted before the bucket can be deleted. If the bucket is not empty, 
        # BucketNotEmpty will be raised.
        #
        # You can side step this issue by passing the :force => true option to delete which will take care of
        # emptying the bucket before deleting it.
        #
        #   Bucket.delete('photos', :force => true)
        #
        # Only the owner of a bucket can delete a bucket, regardless of the bucket's access control policy.
        def delete(name = nil, options = {})
          find(name).delete_all if options[:force]
          
          name = path(name)
          Base.delete(name).success?
        end
        
        # List all your buckets. This is a convenient wrapper around AWS::S3::Service.buckets.
        def list(reload = false)
          Service.buckets(reload)
        end
        
        private
          def validate_name!(name)
            raise InvalidBucketName.new(name) unless name =~ /^[-\w.]{3,255}$/
          end
          
          def path(name, options = {})
            if name.is_a?(Hash)
              options = name
              name    = nil
            end
            "/#{bucket_name(name)}#{RequestOptions.process(options).to_query_string}"
          end
      end
      
      attr_reader :object_cache #:nodoc:
      
      include Enumerable
      
      def initialize(attributes = {}) #:nodoc:
        super
        @object_cache = []
        build_contents!
      end
      
      # Fetches the object named <tt>object_key</tt>, or nil if the bucket does not contain an object with the 
      # specified key.
      #
      #   bucket.objects
      #   => [#<AWS::S3::S3Object '/marcel_molina/beluga_baby.jpg'>,
      #       #<AWS::S3::S3Object '/marcel_molina/tongue_overload.jpg'>]
      #   bucket['beluga_baby.jpg']
      #   => #<AWS::S3::S3Object '/marcel_molina/beluga_baby.jpg'>
      def [](object_key)
        detect {|file| file.key == object_key.to_s}
      end
      
      # Initializes a new S3Object belonging to the current bucket.
      #
      #   object = bucket.new_object
      #   object.value = data
      #   object.key   = 'classical/mahler.mp3'
      #   object.store
      #   bucket.objects.include?(object)
      #   => true
      def new_object(attributes = {})
        object = S3Object.new(attributes)
        register(object)
        object
      end
      
      # List S3Object's of the bucket.
      #
      # Once fetched the objects will be cached. You can reload the objects by passing <tt>:reload</tt>.
      #
      #   bucket.objects(:reload)
      #
      # You can also filter the objects using the same options listed in Bucket.objects.
      #
      #   bucket.objects(:prefix => 'jazz')
      #
      # Using these filtering options will implictly reload the objects.
      #
      # To reclaim all the objects for the bucket you can pass in :reload again.
      def objects(options = {})
        if options.is_a?(Hash)
          reload = !options.empty?
        else
          reload  = options
          options = {}
        end
        
        reload!(options) if reload || object_cache.empty?
        object_cache
      end
      
      # Iterates over the objects in the bucket.
      #
      #   bucket.each do |object|
      #     # Do something with the object ...
      #   end
      def each(&block)
        # Dup the collection since we might be destructively modifying the object_cache during the iteration.
        objects.dup.each(&block)
      end
      
      # Returns true if there are no objects in the bucket.
      def empty?
        objects.empty?
      end
      
      # Returns the number of objects in the bucket.
      def size
        objects.size
      end
      
      # Deletes the bucket. See its class method counter part Bucket.delete for caveats about bucket deletion and how to ensure
      # a bucket is deleted no matter what.
      def delete(options = {})
        self.class.delete(name, options)
      end
      
      # Delete all files in the bucket. Use with caution. Can not be undone.
      def delete_all
        each do |object|
          object.delete
        end
        self
      end
      alias_method :clear, :delete_all
      
      # Buckets observe their objects and have this method called when one of their objects
      # is either stored or deleted.
      def update(action, object) #:nodoc:        
        case action
        when :stored  then add object unless objects.include?(object)
        when :deleted then object_cache.delete(object)
        end
      end
      
      private        
        def build_contents!
          return unless has_contents?
          attributes.delete('contents').each do |content|
            add new_object(content)
          end
        end
        
        def has_contents?
          attributes.has_key?('contents')
        end
        
        def add(object)
          register(object)
          object_cache << object
        end
        
        def register(object)
          object.bucket = self
        end
        
        def reload!(options = {})
          object_cache.clear
          self.class.objects(name, options).each do |object| 
            add object
          end
        end         
    end
  end
end