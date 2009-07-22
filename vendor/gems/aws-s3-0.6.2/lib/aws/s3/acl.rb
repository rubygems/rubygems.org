module AWS
  module S3
    # By default buckets are private. This means that only the owner has access rights to the bucket and its objects. 
    # Objects in that bucket inherit the permission of the bucket unless otherwise specified. When an object is private, the owner can 
    # generate a signed url that exposes the object to anyone who has that url. Alternatively, buckets and objects can be given other 
    # access levels. Several canned access levels are defined:
    # 
    # * <tt>:private</tt> - Owner gets FULL_CONTROL. No one else has any access rights. This is the default.
    # * <tt>:public_read</tt> - Owner gets FULL_CONTROL and the anonymous principal is granted READ access. If this policy is used on an object, it can be read from a browser with no authentication.
    # * <tt>:public_read_write</tt> - Owner gets FULL_CONTROL, the anonymous principal is granted READ and WRITE access. This is a useful policy to apply to a bucket, if you intend for any anonymous user to PUT objects into the bucket.
    # * <tt>:authenticated_read</tt> - Owner gets FULL_CONTROL, and any principal authenticated as a registered Amazon S3 user is granted READ access.
    # 
    # You can set a canned access level when you create a bucket or an object by using the <tt>:access</tt> option:
    # 
    #   S3Object.store(
    #     'kiss.jpg', 
    #     data, 
    #     'marcel', 
    #     :access => :public_read
    #   )
    # 
    # Since the image we created is publicly readable, we can access it directly from a browser by going to the corresponding bucket name 
    # and specifying the object's key without a special authenticated url:
    # 
    #  http://s3.amazonaws.com/marcel/kiss.jpg
    # 
    # ==== Building custum access policies
    # 
    # For both buckets and objects, you can use the <tt>acl</tt> method to see its access control policy:
    # 
    #   policy = S3Object.acl('kiss.jpg', 'marcel')
    #   pp policy.grants
    #   [#<AWS::S3::ACL::Grant FULL_CONTROL to noradio>,
    #    #<AWS::S3::ACL::Grant READ to AllUsers Group>]
    # 
    # Policies are made up of one or more grants which grant a specific permission to some grantee. Here we see the default FULL_CONTROL grant 
    # to the owner of this object. There is also READ permission granted to the Allusers Group, which means anyone has read access for the object.
    # 
    # Say we wanted to grant access to anyone to read the access policy of this object. The current READ permission only grants them permission to read 
    # the object itself (for example, from a browser) but it does not allow them to read the access policy. For that we will need to grant the AllUsers group the READ_ACP permission.
    # 
    # First we'll create a new grant object:
    # 
    #   grant = ACL::Grant.new
    #   # => #<AWS::S3::ACL::Grant (permission) to (grantee)>
    #   grant.permission = 'READ_ACP'
    # 
    # Now we need to indicate who this grant is for. In other words, who the grantee is:
    # 
    #   grantee = ACL::Grantee.new
    #   # => #<AWS::S3::ACL::Grantee (xsi not set yet)>
    # 
    # There are three ways to specify a grantee: 1) by their internal amazon id, such as the one returned with an object's Owner, 
    # 2) by their Amazon account email address or 3) by specifying a group. As of this writing you can not create custom groups, but 
    # Amazon does provide three already: AllUsers, Authenticated and LogDelivery. In this case we want to provide the grant to all users. 
    # This effectively means "anyone".
    # 
    #   grantee.group = 'AllUsers'
    # 
    # Now that our grantee is setup, we'll associate it with the grant:
    # 
    #   grant.grantee = grantee
    #   grant
    #   # => #<AWS::S3::ACL::Grant READ_ACP to AllUsers Group>
    # 
    # Are grant has all the information we need. Now that it's ready, we'll add it on to the object's access control policy's list of grants:
    # 
    #   policy.grants << grant
    #   pp policy.grants
    #   [#<AWS::S3::ACL::Grant FULL_CONTROL to noradio>,
    #    #<AWS::S3::ACL::Grant READ to AllUsers Group>,
    #    #<AWS::S3::ACL::Grant READ_ACP to AllUsers Group>]
    # 
    # Now that the policy has the new grant, we reuse the <tt>acl</tt> method to persist the policy change:
    # 
    #   S3Object.acl('kiss.jpg', 'marcel', policy)
    # 
    # If we fetch the object's policy again, we see that the grant has been added:
    # 
    #   pp S3Object.acl('kiss.jpg', 'marcel').grants
    #   [#<AWS::S3::ACL::Grant FULL_CONTROL to noradio>,
    #    #<AWS::S3::ACL::Grant READ to AllUsers Group>,
    #    #<AWS::S3::ACL::Grant READ_ACP to AllUsers Group>]
    # 
    # If we were to access this object's acl url from a browser: 
    # 
    #   http://s3.amazonaws.com/marcel/kiss.jpg?acl
    # 
    # we would be shown its access control policy.
    # 
    # ==== Pre-prepared grants
    # 
    # Alternatively, the ACL::Grant class defines a set of stock grant policies that you can fetch by name. In most cases, you can 
    # just use one of these pre-prepared grants rather than building grants by hand. Two of these stock policies are <tt>:public_read</tt> 
    # and <tt>:public_read_acp</tt>, which happen to be the two grants that we built by hand above. In this case we could have simply written:
    # 
    #   policy.grants << ACL::Grant.grant(:public_read)
    #   policy.grants << ACL::Grant.grant(:public_read_acp)
    #   S3Object.acl('kiss.jpg', 'marcel', policy)
    # 
    # The full details can be found in ACL::Policy, ACL::Grant and ACL::Grantee.
    module ACL
      # The ACL::Policy class lets you inspect and modify access controls for buckets and objects.
      # A policy is made up of one or more Grants which specify a permission and a Grantee to whom that permission is granted.
      #
      # Buckets and objects are given a default access policy which contains one grant permitting the owner of the bucket or object
      # FULL_CONTROL over its contents. This means they can read the object, write to the object, as well as read and write its
      # policy.
      #
      # The <tt>acl</tt> method for both buckets and objects returns the policy object for that entity:
      #
      #   policy = Bucket.acl('some-bucket')
      #
      # The <tt>grants</tt> method of a policy exposes its grants. You can treat this collection as an array and push new grants onto it:
      #
      #   policy.grants << grant
      #
      # Check the documentation for Grant and Grantee for more details on how to create new grants.
      class Policy
        include SelectiveAttributeProxy #:nodoc:
        attr_accessor :owner, :grants
        
        def initialize(attributes = {})
          @attributes = attributes
          @grants     = [].extend(GrantListExtensions)
          extract_owner!  if owner?
          extract_grants! if grants?
        end
        
        # The xml representation of the policy.
        def to_xml
          Builder.new(owner, grants).to_s
        end

        private
        
          def owner?
            attributes.has_key?('owner') || !owner.nil?
          end
          
          def grants?
            (attributes.has_key?('access_control_list') && attributes['access_control_list']['grant']) || !grants.empty?
          end
          
          def extract_owner!
            @owner = Owner.new(attributes.delete('owner'))
          end
          
          def extract_grants!
            attributes['access_control_list']['grant'].each do |grant|
              grants << Grant.new(grant)
            end
          end
          
          module GrantListExtensions #:nodoc:
            def include?(grant)
              case grant
              when Symbol
                super(ACL::Grant.grant(grant))
              else
                super
              end
            end
            
            def delete(grant)
              case grant
              when Symbol
                super(ACL::Grant.grant(grant))
              else
                super
              end
            end
            
            # Two grant lists are equal if they have identical grants both in terms of permission and grantee.
            def ==(grants)
              size == grants.size && all? {|grant| grants.include?(grant)}
            end
          end
        
        class Builder < XmlGenerator #:nodoc:
          attr_reader :owner, :grants
          def initialize(owner, grants)
            @owner  = owner
            @grants = grants.uniq # There could be some duplicate grants
            super()
          end
      
          def build
            xml.tag!('AccessControlPolicy', 'xmlns' => 'http://s3.amazonaws.com/doc/2006-03-01/') do
              xml.Owner do
                xml.ID owner.id
                xml.DisplayName owner.display_name
              end
              
              xml.AccessControlList do
                xml << grants.map {|grant| grant.to_xml}.join("\n")
              end
            end
          end
        end
      end
      
      # A Policy is made up of one or more Grant objects. A grant sets a specific permission and grants it to the associated grantee.
      #
      # When creating a new grant to add to a policy, you need only set its permission and then associate with a Grantee.
      #
      #   grant = ACL::Grant.new
      #   => #<AWS::S3::ACL::Grant (permission) to (grantee)>
      #
      # Here we see that neither the permission nor the grantee have been set. Let's make this grant provide the READ permission.
      #
      #   grant.permission = 'READ'
      #   grant
      #   => #<AWS::S3::ACL::Grant READ to (grantee)>
      #
      # Now let's assume we have a grantee to the AllUsers group already set up. Just associate that grantee with our grant. 
      #
      #   grant.grantee = all_users_group_grantee
      #   grant
      #   => #<AWS::S3::ACL::Grant READ to AllUsers Group>
      #
      # And now are grant is complete. It provides READ permission to the AllUsers group, effectively making this object publicly readable
      # without any authorization.
      #
      # Assuming we have some object's policy available in a local variable called <tt>policy</tt>, we can now add this grant onto its
      # collection of grants.
      #
      #   policy.grants << grant
      #
      # And then we send the updated policy to the S3 servers.
      #
      #   some_s3object.acl(policy)
      class Grant
        include SelectiveAttributeProxy #:nodoc:
        constant :VALID_PERMISSIONS, %w(READ WRITE READ_ACP WRITE_ACP FULL_CONTROL)
        attr_accessor :grantee
        
        class << self
          # Returns stock grants with name <tt>type</tt>.
          #
          #   public_read_grant = ACL::Grant.grant :public_read
          #   => #<AWS::S3::ACL::Grant READ to AllUsers Group>
          #
          # Valid stock grant types are:
          #
          # * <tt>:authenticated_read</tt>
          # * <tt>:authenticated_read_acp</tt>
          # * <tt>:authenticated_write</tt>
          # * <tt>:authenticated_write_acp</tt>
          # * <tt>:logging_read</tt>
          # * <tt>:logging_read_acp</tt>
          # * <tt>:logging_write</tt>
          # * <tt>:logging_write_acp</tt>
          # * <tt>:public_read</tt>
          # * <tt>:public_read_acp</tt>
          # * <tt>:public_write</tt>
          # * <tt>:public_write_acp</tt>
          def grant(type)
            case type
            when *stock_grant_map.keys
              build_stock_grant_for type
            else
              raise ArgumentError, "Unknown grant type `#{type}'"
            end
          end
          
          private
            def stock_grant_map
              grant        = lambda {|permission, group| {:permission => permission, :group => group}}
              groups       = {:public => 'AllUsers', :authenticated => 'Authenticated', :logging => 'LogDelivery'}
              permissions  = %w(READ WRITE READ_ACP WRITE_ACP)
              stock_grants = {}
              groups.each do |grant_group_name, group_name|
                permissions.each do |permission|
                  stock_grants["#{grant_group_name}_#{permission.downcase}".to_sym] = grant[permission, group_name]
                end
              end
              stock_grants
            end
            memoized :stock_grant_map
            
            def build_stock_grant_for(type)
              stock_grant = stock_grant_map[type]
              grant = new do |g|
                g.permission = stock_grant[:permission]
              end
              grant.grantee = Grantee.new do |gr|
                gr.group = stock_grant[:group]
              end
              grant
            end
        end
        
        def initialize(attributes = {})
          attributes = {'permission' => nil}.merge(attributes)
          @attributes = attributes
          extract_grantee!
          yield self if block_given?
        end
        
        # Set the permission for this grant.
        #
        #   grant.permission = 'READ'
        #   grant
        #   => #<AWS::S3::ACL::Grant READ to (grantee)>
        #
        # If the specified permisison level is not valid, an <tt>InvalidAccessControlLevel</tt> exception will be raised.
        def permission=(permission_level)
          unless self.class.valid_permissions.include?(permission_level)
            raise InvalidAccessControlLevel.new(self.class.valid_permissions, permission_level)
          end
          attributes['permission'] = permission_level
        end
        
        # The xml representation of this grant.
        def to_xml
          Builder.new(permission, grantee).to_s
        end
        
        def inspect #:nodoc:
          "#<%s:0x%s %s>" % [self.class, object_id, self]
        end
        
        def to_s #:nodoc:
          [permission || '(permission)', 'to', grantee ? grantee.type_representation : '(grantee)'].join ' '
        end
        
        def eql?(grant) #:nodoc:
          # This won't work for an unposted AmazonCustomerByEmail because of the normalization
          # to CanonicalUser but it will work for groups.
          to_s == grant.to_s
        end
        alias_method :==, :eql?
                
        def hash #:nodoc:
          to_s.hash
        end
        
        private
        
          def extract_grantee!
            @grantee = Grantee.new(attributes['grantee']) if attributes['grantee']
          end
          
        class Builder < XmlGenerator #:nodoc:
          attr_reader :grantee, :permission
      
          def initialize(permission, grantee)
            @permission = permission
            @grantee    = grantee
            super()
          end
      
          def build
            xml.Grant do
              xml << grantee.to_xml
              xml.Permission permission
            end
          end
        end
      end
      
      # Grants bestow a access permission to grantees. Each grant of some access control list Policy is associated with a grantee.
      # There are three ways of specifying a grantee at the time of this writing.
      #
      # * By canonical user - This format uses the <tt>id</tt> of a given Amazon account. The id value for a given account is available in the
      #  Owner object of a bucket, object or policy.
      #
      #   grantee.id = 'bb2041a25975c3d4ce9775fe9e93e5b77a6a9fad97dc7e00686191f3790b13f1'
      #
      # Often the id will just be fetched from some owner object.
      #
      #   grantee.id = some_object.owner.id
      # 
      # * By amazon email address - You can specify an email address for any Amazon account. The Amazon account need not be signed up with the S3 service.
      # though it must be unique across the entire Amazon system. This email address is normalized into a canonical user representation once the grant
      # has been sent back up to the S3 servers.
      #
      #   grantee.email_address = 'joe@example.org'
      #
      # * By group - As of this writing you can not create custom groups, but Amazon provides three group that you can use. See the documentation for the
      # Grantee.group= method for details.
      #
      #   grantee.group = 'Authenticated'
      class Grantee
        include SelectiveAttributeProxy #:nodoc:
        
        undef_method :id if method_defined?(:id) # Get rid of Object#id
        
        def initialize(attributes = {})
          # Set default values for attributes that may not be passed in but we still want the object
          # to respond to
          attributes = {'id' => nil, 'display_name' => nil, 'email_address' => nil, 'uri' => nil}.merge(attributes)
          @attributes = attributes
          extract_type!
          yield self if block_given?
        end
        
        # The xml representation of the current grantee object.
        def to_xml
          Builder.new(self).to_s
        end
        
        # Returns the type of grantee. Will be one of <tt>CanonicalUser</tt>, <tt>AmazonCustomerByEmail</tt> or <tt>Group</tt>.
        def type
          return attributes['type'] if attributes['type']
          
          # Lookups are in order of preference so if, for example, you set the uri but display_name and id are also
          # set, we'd rather go with the canonical representation.
          if display_name && id
            'CanonicalUser'
          elsif email_address
            'AmazonCustomerByEmail'
          elsif uri
            'Group'
          end
        end
        
        # Sets the grantee's group by name.
        #
        #   grantee.group = 'AllUsers'
        #
        # Currently, valid groups defined by S3 are:
        #
        # * <tt>AllUsers</tt>: This group represents anyone. In other words, an anonymous request.
        # * <tt>Authenticated</tt>: Any authenticated account on the S3 service.
        # * <tt>LogDelivery</tt>: The entity that delivers bucket access logs.
        def group=(group_name)
          section  = %w(AllUsers Authenticated).include?(group_name) ? 'global' : 's3'
          self.uri = "http://acs.amazonaws.com/groups/#{section}/#{group_name}"
        end
        
        # Returns the grantee's group. If the grantee is not a group, <tt>nil</tt> is returned.
        def group
          return unless uri
          uri[%r([^/]+$)]
        end
        
        def type_representation #:nodoc:
          case type
          when 'CanonicalUser'          then display_name || id
          when 'AmazonCustomerByEmail'  then email_address
          when 'Group'                  then "#{group} Group"
          end
        end
        
        def inspect #:nodoc:
          "#<%s:0x%s %s>" %  [self.class, object_id, type_representation || '(type not set yet)']
        end
        
        private
          def extract_type!
            attributes['type'] = attributes.delete('xsi:type')
          end            

        class Builder < XmlGenerator #:nodoc:
          
          def initialize(grantee)
            @grantee = grantee
            super()
          end
          
          def build
            xml.tag!('Grantee', attributes) do
              representation
            end
          end
          
          private
            attr_reader :grantee
            
            def representation
              case grantee.type
              when 'CanonicalUser'
                xml.ID grantee.id
                xml.DisplayName grantee.display_name
              when 'AmazonCustomerByEmail'
                xml.EmailAddress grantee.email_address
              when 'Group'
                xml.URI grantee.uri
              end
            end
            
            def attributes
              {'xsi:type' => grantee.type, 'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance'}
            end
        end
      end
      
      module Bucket
        def self.included(klass) #:nodoc:
          klass.extend(ClassMethods)
        end
        
        module ClassMethods
          # The acl method is the single point of entry for reading and writing access control list policies for a given bucket.
          #   
          #   # Fetch the acl for the 'marcel' bucket
          #   policy = Bucket.acl 'marcel'
          #
          #   # Modify the policy ...
          #   # ...
          # 
          #   # Send updated policy back to the S3 servers
          #   Bucket.acl 'marcel', policy 
          def acl(name = nil, policy = nil)
            if name.is_a?(ACL::Policy)
              policy = name
              name   = nil
            end

            path = path(name) << '?acl'
            respond_with ACL::Policy::Response do
              policy ? put(path, {}, policy.to_xml) : ACL::Policy.new(get(path(name) << '?acl').policy)
            end
          end
        end
        
        # The acl method returns and updates the acl for a given bucket.
        #
        #   # Fetch a bucket
        #   bucket = Bucket.find 'marcel'
        #
        #   # Add a grant to the bucket's policy
        #   bucket.acl.grants << some_grant
        #
        #   # Write the changes to the policy
        #   bucket.acl(bucket.acl)
        def acl(reload = false)
          policy = reload.is_a?(ACL::Policy) ? reload : nil
          expirable_memoize(reload) do
            self.class.acl(name, policy) if policy
            self.class.acl(name)
          end
        end
      end
      
      module S3Object
        def self.included(klass) #:nodoc:
          klass.extend(ClassMethods)
        end
        
        module ClassMethods
          # The acl method is the single point of entry for reading and writing access control list policies for a given object.
          #   
          #   # Fetch the acl for the 'kiss.jpg' object in the 'marcel' bucket
          #   policy = S3Object.acl 'kiss.jpg', 'marcel'
          #
          #   # Modify the policy ...
          #   # ...
          # 
          #   # Send updated policy back to the S3 servers
          #   S3Object.acl 'kiss.jpg', 'marcel', policy
          def acl(name, bucket = nil, policy = nil)
            # We're using the second argument as the ACL::Policy
            if bucket.is_a?(ACL::Policy)
              policy = bucket
              bucket = nil
            end

            bucket = bucket_name(bucket)
            path   = path!(bucket, name) << '?acl'

            respond_with ACL::Policy::Response do
              policy ? put(path, {}, policy.to_xml) : ACL::Policy.new(get(path).policy)
            end
          end
        end
        
        # The acl method returns and updates the acl for a given s3 object.
        #
        #   # Fetch a the object
        #   object = S3Object.find 'kiss.jpg', 'marcel'
        #
        #   # Add a grant to the object's
        #   object.acl.grants << some_grant
        #
        #   # Write the changes to the policy
        #   object.acl(object.acl)
        def acl(reload = false)
          policy = reload.is_a?(ACL::Policy) ? reload : nil
          expirable_memoize(reload) do
            self.class.acl(key, bucket.name, policy) if policy
            self.class.acl(key, bucket.name)
          end
        end
      end
          
      class OptionProcessor #:nodoc:
        attr_reader :options
        class << self
          def process!(options)
            new(options).process!
          end
        end

        def initialize(options)
          options.to_normalized_options!
          @options      = options
          @access_level = extract_access_level
        end

        def process!
          return unless access_level_specified?
          validate!
          options['x-amz-acl'] = access_level
        end

        private
          def extract_access_level
             options.delete('access') || options.delete('x-amz-acl')
          end

          def validate!
            raise InvalidAccessControlLevel.new(valid_levels, access_level) unless valid?
          end

          def valid?
            valid_levels.include?(access_level)
          end

          def access_level_specified?
            !@access_level.nil?
          end

          def valid_levels
            %w(private public-read public-read-write authenticated-read)
          end

          def access_level
            @normalized_access_level ||= @access_level.to_header
          end
      end
    end
  end
end
