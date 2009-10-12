require File.dirname(__FILE__) + '/test_helper'

class RemoteLoggingTest < Test::Unit::TestCase
  def setup
    establish_real_connection
  end
  
  def teardown
    disconnect!
  end
  
  def test_logging
    Bucket.create(TEST_BUCKET) # Clear out any custom grants
    
    # Confirm that logging is not enabled on the test bucket
    
    assert !Bucket.logging_enabled_for?(TEST_BUCKET)
    assert !Bucket.find(TEST_BUCKET).logging_enabled?
    
    assert_equal [], Bucket.logs_for(TEST_BUCKET)
    
    # Confirm the current bucket doesn't have logging grants
    
    policy = Bucket.acl(TEST_BUCKET)
    assert !policy.grants.include?(:logging_read_acp)
    assert !policy.grants.include?(:logging_write)
    
    # Confirm that we can enable logging
    
    assert_nothing_raised do
      Bucket.enable_logging_for TEST_BUCKET
    end
    
    # Confirm enabling logging worked
    
    assert Service.response.success?
        
    assert Bucket.logging_enabled_for?(TEST_BUCKET)
    assert Bucket.find(TEST_BUCKET).logging_enabled?
    
    # Confirm the appropriate grants were added
    
    policy = Bucket.acl(TEST_BUCKET)
    assert policy.grants.include?(:logging_read_acp)
    assert policy.grants.include?(:logging_write)
    
    # Confirm logging status used defaults
    
    logging_status = Bucket.logging_status_for TEST_BUCKET
    assert_equal TEST_BUCKET, logging_status.target_bucket
    assert_equal 'log-', logging_status.target_prefix
    
    # Confirm we can update the logging status
    
    logging_status.target_prefix = 'access-log-'
    
    assert_nothing_raised do
      Bucket.logging_status_for TEST_BUCKET, logging_status
    end
    
    assert Service.response.success?
    
    logging_status = Bucket.logging_status_for TEST_BUCKET
    assert_equal 'access-log-', logging_status.target_prefix
    
    # Confirm we can make a request for the bucket's logs
    
    assert_nothing_raised do
      Bucket.logs_for TEST_BUCKET
    end
    
    # Confirm we can disable logging
    
    assert_nothing_raised do
      Bucket.disable_logging_for(TEST_BUCKET)
    end
    
    assert Service.response.success?
    
    assert !Bucket.logging_enabled_for?(TEST_BUCKET)
  end
end