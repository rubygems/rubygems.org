require File.dirname(__FILE__) + '/test_helper'

class BaseTest < Test::Unit::TestCase  
  def test_connection_established
    assert_raises(NoConnectionEstablished) do
      Base.connection
    end
    
    Base.establish_connection!(:access_key_id => '123', :secret_access_key => 'abc')
    assert_kind_of Connection, Base.connection
    
    instance = Base.new
    assert_equal instance.send(:connection), Base.connection
    assert_equal instance.send(:http), Base.connection.http
  end
  
  def test_respond_with
    assert_equal Base::Response, Base.send(:response_class)
    Base.send(:respond_with, Bucket::Response) do
      assert_equal Bucket::Response, Base.send(:response_class)
    end
    assert_equal Base::Response, Base.send(:response_class)
  end
  
  def test_request_tries_again_when_encountering_an_internal_error
    mock_connection_for(Bucket, :returns => [
      # First request is an internal error
      {:body => Fixtures::Errors.internal_error, :code => 500, :error => true},
      # Second request is a success
      {:body => Fixtures::Buckets.empty_bucket,  :code => 200}
    ])
    bucket = nil # Block scope hack
    assert_nothing_raised do
      bucket = Bucket.find('marcel')
    end
    # Don't call objects 'cause we don't want to make another request
    assert bucket.object_cache.empty?
  end
  
  def test_request_tries_up_to_three_times
    mock_connection_for(Bucket, :returns => [
      # First request is an internal error
      {:body => Fixtures::Errors.internal_error, :code => 500, :error => true},
      # Second request is also an internal error
      {:body => Fixtures::Errors.internal_error, :code => 500, :error => true},
      # Ditto third
      {:body => Fixtures::Errors.internal_error, :code => 500, :error => true},
      # Fourth works
      {:body => Fixtures::Buckets.empty_bucket,  :code => 200}
    ])
    bucket = nil # Block scope hack
    assert_nothing_raised do
      bucket = Bucket.find('marcel')
    end
    # Don't call objects 'cause we don't want to make another request
    assert bucket.object_cache.empty?
  end
  
  def test_request_tries_again_three_times_and_gives_up
    mock_connection_for(Bucket, :returns => [
      # First request is an internal error
      {:body => Fixtures::Errors.internal_error, :code => 500, :error => true},
      # Second request is also an internal error
      {:body => Fixtures::Errors.internal_error, :code => 500, :error => true},
      # Ditto third
      {:body => Fixtures::Errors.internal_error, :code => 500, :error => true},
      # Ditto fourth
      {:body => Fixtures::Errors.internal_error, :code => 500, :error => true},
    ])
    assert_raises(InternalError) do
      Bucket.find('marcel')
    end
  end
end

class MultiConnectionsTest < Test::Unit::TestCase
  class ClassToTestSettingCurrentBucket < Base
    set_current_bucket_to 'foo'
  end

  def setup
    Base.send(:connections).clear
  end
  
  def test_default_connection_options_are_used_for_subsequent_connections    
    assert !Base.connected?
    
    assert_raises(MissingAccessKey) do
      Base.establish_connection!
    end
    
    assert !Base.connected?
    
    assert_raises(NoConnectionEstablished) do
      Base.connection
    end
    
    assert_nothing_raised do
      Base.establish_connection!(:access_key_id => '123', :secret_access_key => 'abc')
    end
    
    assert Base.connected?
    
    assert_nothing_raised do
      Base.connection
    end
    
    # All subclasses are currently using the default connection
    assert_equal Base.connection, Bucket.connection
    
    # No need to pass in the required options. The default connection will supply them
    assert_nothing_raised do
      Bucket.establish_connection!(:server => 'foo.s3.amazonaws.com')
    end
    
    assert Base.connection != Bucket.connection
    assert_equal '123', Bucket.connection.access_key_id
    assert_equal 'foo', Bucket.connection.subdomain
  end
  
  def test_current_bucket
    Base.establish_connection!(:access_key_id => '123', :secret_access_key => 'abc') 
    assert_raises(CurrentBucketNotSpecified) do
      Base.current_bucket
    end
    
    S3Object.establish_connection!(:server => 'foo-bucket.s3.amazonaws.com')
    assert_nothing_raised do
      assert_equal 'foo-bucket', S3Object.current_bucket
    end
  end
  
  def test_setting_the_current_bucket
    assert_equal 'foo', ClassToTestSettingCurrentBucket.current_bucket
  end
end
