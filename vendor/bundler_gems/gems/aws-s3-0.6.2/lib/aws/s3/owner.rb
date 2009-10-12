module AWS
  module S3
    # Entities in S3 have an associated owner (the person who created them). The owner is a canonical representation of an 
    # entity in the S3 system. It has an <tt>id</tt> and a <tt>display_name</tt>. 
    # 
    # These attributes can be used when specifying a ACL::Grantee for an ACL::Grant.
    #
    # You can retrieve the owner of the current account by calling Owner.current.
    class Owner
      undef_method :id if method_defined?(:id) # Get rid of Object#id
      include SelectiveAttributeProxy
      
      class << self
        # The owner of the current account.
        def current
          response = Service.get('/')
          new(response.parsed['owner']) if response.parsed['owner']
        end
        memoized :current
      end
      
      def initialize(attributes = {}) #:nodoc:
        @attributes = attributes
      end
      
      def ==(other_owner) #:nodoc:
        hash == other_owner.hash
      end
      
      def hash #:nodoc
        [id, display_name].join.hash
      end
      
      private
        def proxiable_attribute?(name)
          valid_attributes.include?(name)
        end
        
        def valid_attributes
          %w(id display_name)
        end
    end
  end
end