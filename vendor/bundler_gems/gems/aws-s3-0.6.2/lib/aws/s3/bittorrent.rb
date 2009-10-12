module AWS
  module S3
    # Objects on S3 can be distributed via the BitTorrent file sharing protocol. 
    #
    # You can get a torrent file for an object by calling <tt>torrent_for</tt>:
    #
    #   S3Object.torrent_for 'kiss.jpg', 'marcel'
    #
    # Or just call the <tt>torrent</tt> method if you already have the object:
    #
    #   song = S3Object.find 'kiss.jpg', 'marcel'
    #   song.torrent
    #
    # Calling <tt>grant_torrent_access_to</tt> on a object will allow anyone to anonymously
    # fetch the torrent file for that object:
    #
    #   S3Object.grant_torrent_access_to 'kiss.jpg', 'marcel'
    #
    # Anonymous requests to
    #
    #   http://s3.amazonaws.com/marcel/kiss.jpg?torrent
    #
    # will serve up the torrent file for that object.
    module BitTorrent
      def self.included(klass) #:nodoc:
        klass.extend ClassMethods
      end
      
      # Adds methods to S3Object for accessing the torrent of a given object.
      module ClassMethods
        # Returns the torrent file for the object with the given <tt>key</tt>.
        def torrent_for(key, bucket = nil)
          get(path!(bucket, key) << '?torrent').body
        end
        alias_method :torrent, :torrent_for
        
        # Grants access to the object with the given <tt>key</tt> to be accessible as a torrent.
        def grant_torrent_access_to(key, bucket = nil)
          policy = acl(key, bucket)
          return true if policy.grants.include?(:public_read)
          policy.grants << ACL::Grant.grant(:public_read)
          acl(key, bucket, policy)
        end
        alias_method :grant_torrent_access, :grant_torrent_access_to
      end
      
      # Returns the torrent file for the object.
      def torrent
        self.class.torrent_for(key, bucket.name)
      end
      
      # Grants torrent access publicly to anyone who requests it on this object.
      def grant_torrent_access
        self.class.grant_torrent_access_to(key, bucket.name)
      end
    end
  end
end