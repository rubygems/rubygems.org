require File.dirname(__FILE__) + '/test_helper'

class RemoteACLTest < Test::Unit::TestCase
  
  def setup
    establish_real_connection
  end
  
  def teardown
    disconnect!
  end
  
  def test_acl
    Bucket.create(TEST_BUCKET) # Wipe out the existing bucket's ACL
      
    bucket_policy = Bucket.acl(TEST_BUCKET)
    assert_equal 1, bucket_policy.grants.size
    assert !bucket_policy.grants.include?(:public_read_acp)
    
    bucket_policy.grants << ACL::Grant.grant(:public_read_acp)
    
    assert_nothing_raised do
      Bucket.acl(TEST_BUCKET, bucket_policy)
    end
    
    bucket = Bucket.find(TEST_BUCKET)
    assert bucket.acl.grants.include?(:public_read_acp)

    bucket.acl.grants.pop # Get rid of the newly added grant
    
    assert !bucket.acl.grants.include?(:public_read_acp)
    bucket.acl(bucket.acl) # Update its acl
    assert Service.response.success?
    
    bucket_policy = Bucket.acl(TEST_BUCKET)
    assert_equal 1, bucket_policy.grants.size
    assert !bucket_policy.grants.include?(:public_read_acp)
    
    S3Object.store('testing-acls', 'the test data', TEST_BUCKET, :content_type => 'text/plain')
    acl = S3Object.acl('testing-acls', TEST_BUCKET)
    
    # Confirm object has the default policy 
    
    assert !acl.grants.empty?
    assert_equal 1, acl.grants.size
    grant = acl.grants.first
    
    assert_equal 'FULL_CONTROL', grant.permission
    
    grantee = grant.grantee
    
    assert acl.owner.id
    assert acl.owner.display_name
    assert grantee.id
    assert grantee.display_name
    
    assert_equal acl.owner.id, grantee.id
    assert_equal acl.owner.display_name, grantee.display_name
    
    assert_equal Owner.current, acl.owner
    
    
    # Manually add read access to an Amazon customer by email address
    
    new_grant                       = ACL::Grant.new
    new_grant.permission            = 'READ'
    new_grant_grantee               = ACL::Grantee.new
    new_grant_grantee.email_address = 'marcel@vernix.org'
    new_grant.grantee = new_grant_grantee
    acl.grants << new_grant
    
    assert_nothing_raised do
      S3Object.acl('testing-acls', TEST_BUCKET, acl)
    end
    
    # Confirm the acl was updated successfully
    
    assert Service.response.success?
    
    acl = S3Object.acl('testing-acls', TEST_BUCKET)
    assert !acl.grants.empty?
    assert_equal 2, acl.grants.size
    new_grant = acl.grants.last
    assert_equal 'READ', new_grant.permission
    
    # Confirm instance method has same result
    
    assert_equal acl.grants, S3Object.find('testing-acls', TEST_BUCKET).acl.grants
    
    # Get rid of the grant we just added
    
    acl.grants.pop
    
    # Confirm acl class method sees that the bucket option is being used to put a new acl
    
    assert_nothing_raised do
      TestS3Object.acl('testing-acls', acl)
    end
    
    assert Service.response.success?
    
    acl = TestS3Object.acl('testing-acls')
    
    # Confirm added grant was removed from the policy
    
    assert !acl.grants.empty?
    assert_equal 1, acl.grants.size
    grant = acl.grants.first
    assert_equal 'FULL_CONTROL', grant.permission
    
    assert_nothing_raised do
      S3Object.delete('testing-acls', TEST_BUCKET)
    end
    
    assert Service.response.success?
  end
end