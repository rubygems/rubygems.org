require File.dirname(__FILE__) + '/test_helper'

class PolicyReadingTest < Test::Unit::TestCase
  
  def setup
    @policy = prepare_policy
  end
  
  def test_policy_owner
    assert_kind_of Owner, @policy.owner
    assert_equal 'bb2041a25975c3d4ce9775fe9e93e5b77a6a9fad97dc7e00686191f3790b13f1', @policy.owner.id
    assert_equal 'mmolina@onramp.net', @policy.owner.display_name
  end
  
  def test_grants
    assert @policy.grants
    assert !@policy.grants.empty?
    grant = @policy.grants.first
    assert_kind_of ACL::Grant, grant
    assert_equal 'FULL_CONTROL', grant.permission
  end
  
  def test_grants_have_grantee
    grant = @policy.grants.first
    assert grantee = grant.grantee
    assert_kind_of ACL::Grantee, grantee
    assert_equal 'bb2041a25975c3d4ce9775fe9e93e5b77a6a9fad97dc7e00686191f3790b13f1', grantee.id
    assert_equal 'mmolina@onramp.net', grantee.display_name
    assert_equal 'CanonicalUser', grantee.type
  end
  
  def test_grantee_always_responds_to_email_address
    assert_nothing_raised do
      @policy.grants.first.grantee.email_address
    end
  end
  
  private
    def prepare_policy
      ACL::Policy.new(parsed_policy)
    end
  
    def parsed_policy
      Parsing::XmlParser.new Fixtures::Policies.policy_with_one_grant
    end
end

class PolicyWritingTest < PolicyReadingTest
  
  def setup
    policy = prepare_policy
    # Dump the policy to xml and retranslate it back from the xml then run all the tests in the xml reading
    # test. This round tripping indirectly asserts that the original xml document is the same as the to_xml
    # dump.
    @policy = ACL::Policy.new(Parsing::XmlParser.new(policy.to_xml))
  end
  
end

class PolicyTest < Test::Unit::TestCase
  def test_building_policy_by_hand
    policy = grant = grantee = nil
    assert_nothing_raised do
      policy                = ACL::Policy.new
      grant                 = ACL::Grant.new
      grantee               = ACL::Grantee.new
      grantee.email_address = 'marcel@vernix.org'
      grant.permission      = 'READ_ACP'
      grant.grantee         = grantee
      policy.grants << grant
      policy.owner          = Owner.new('id' => '123456789', 'display_name' => 'noradio')
    end
    
    assert_nothing_raised do
      policy.to_xml
    end
    
    assert !policy.grants.empty?
    assert_equal 1, policy.grants.size
    assert_equal 'READ_ACP', policy.grants.first.permission
  end
  
  def test_include?
    policy = ACL::Policy.new(Parsing::XmlParser.new(Fixtures::Policies.policy_with_one_grant))
    assert !policy.grants.include?(:public_read)
    policy.grants << ACL::Grant.grant(:public_read)
    assert policy.grants.include?(:public_read)
    
    assert policy.grants.include?(ACL::Grant.grant(:public_read))
    [false, 1, '1'].each do |non_grant|
      assert !policy.grants.include?(non_grant)
    end
  end
  
  def test_delete
    policy = ACL::Policy.new(Parsing::XmlParser.new(Fixtures::Policies.policy_with_one_grant))
    policy.grants << ACL::Grant.grant(:public_read)
    assert policy.grants.include?(:public_read)
    assert policy.grants.delete(:public_read)
    assert !policy.grants.include?(:public_read)
    [false, 1, '1'].each do |non_grant|
      assert_nil policy.grants.delete(non_grant)
    end
  end
  
  def test_grant_list_comparison
    policy  = ACL::Policy.new
    policy2 = ACL::Policy.new
    
    grant_names = [:public_read, :public_read_acp, :authenticated_write]
    grant_names.each {|grant_name| policy.grants << ACL::Grant.grant(grant_name)}
    grant_names.reverse_each {|grant_name| policy2.grants << ACL::Grant.grant(grant_name)}
    
    assert_equal policy.grants, policy2.grants
  end
end

class GrantTest < Test::Unit::TestCase
  def test_permission_must_be_valid
    grant = ACL::Grant.new
    assert_nothing_raised do
      grant.permission = 'READ_ACP'
    end
    
    assert_raises(InvalidAccessControlLevel) do
      grant.permission = 'not a valid permission'
    end
  end
  
  def test_stock_grants
    assert_raises(ArgumentError) do
      ACL::Grant.grant :this_is_not_a_stock_grant
    end
    
    grant = nil
    assert_nothing_raised do
      grant = ACL::Grant.grant(:public_read)
    end
    
    assert grant
    assert_kind_of ACL::Grant, grant
    assert_equal 'READ', grant.permission
    assert grant.grantee
    assert_kind_of ACL::Grantee, grant.grantee
    assert_equal 'AllUsers', grant.grantee.group
  end
end

class GranteeTest < Test::Unit::TestCase
  def test_type_inference
    grantee = ACL::Grantee.new
    
    assert_nothing_raised do
      grantee.type
    end
    
    assert_nil grantee.type
    grantee.group = 'AllUsers'
    assert_equal 'AllUsers', grantee.group
    assert_equal 'Group', grantee.type
    grantee.email_address = 'marcel@vernix.org'
    assert_equal 'AmazonCustomerByEmail', grantee.type
    grantee.display_name = 'noradio'
    assert_equal 'AmazonCustomerByEmail', grantee.type
    grantee.id = '123456789'
    assert_equal 'CanonicalUser', grantee.type
  end
  
  def test_type_is_extracted_if_present
    grantee = ACL::Grantee.new('xsi:type' => 'CanonicalUser')
    assert_equal 'CanonicalUser', grantee.type
  end
  
  def test_type_representation
    grantee = ACL::Grantee.new('uri' => 'http://acs.amazonaws.com/groups/global/AllUsers')
    
    assert_equal 'AllUsers Group', grantee.type_representation
    grantee.group = 'AuthenticatedUsers'
    assert_equal 'AuthenticatedUsers Group', grantee.type_representation
    grantee.email_address = 'marcel@vernix.org'
    assert_equal 'marcel@vernix.org', grantee.type_representation
    grantee.display_name = 'noradio'
    grantee.id = '123456789'
    assert_equal 'noradio', grantee.type_representation
  end
end

class ACLOptionProcessorTest < Test::Unit::TestCase
  def test_empty_options
    options = {}
    assert_nothing_raised do
      process! options
    end
    assert_equal({}, options)
  end
  
  def test_invalid_access_level
    options = {:access => :foo}
    assert_raises(InvalidAccessControlLevel) do
      process! options
    end
  end
  
  def test_valid_access_level_is_normalized
    valid_access_levels = [
      {:access     => :private},
      {'access'    => 'private'},
      {:access     => 'private'},
      {'access'    => :private},
      {'x-amz-acl' => 'private'},
      {:x_amz_acl  => :private},
      {:x_amz_acl  => 'private'},
      {'x_amz_acl' => :private}
    ]
    
    valid_access_levels.each do |options|
      assert_nothing_raised do
        process! options
      end
      assert_equal 'private', acl(options)
    end
    
    valid_hyphenated_access_levels = [
      {:access     => :public_read},
      {'access'    => 'public_read'},
      {'access'    => 'public-read'},
      {:access     => 'public_read'},
      {:access     => 'public-read'},
      {'access'    => :public_read},
      
      {'x-amz-acl' => 'public_read'},
      {:x_amz_acl  => :public_read},
      {:x_amz_acl  => 'public_read'},
      {:x_amz_acl  => 'public-read'},
      {'x_amz_acl' => :public_read}
    ]
    
    valid_hyphenated_access_levels.each do |options|
      assert_nothing_raised do
        process! options
      end
      assert_equal 'public-read', acl(options)
    end
  end
  
  private
    def process!(options)
      ACL::OptionProcessor.process!(options)
    end
    
    def acl(options)
      options['x-amz-acl']
    end
end
