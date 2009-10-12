require File.dirname(__FILE__) + '/test_helper'

class RemoteBucketTest < Test::Unit::TestCase
  
  def setup
    establish_real_connection
    assert Bucket.find(TEST_BUCKET).delete_all
  end
  
  def teardown
    disconnect!
  end

  def test_bucket
    # Fetch the testing bucket
    
    bucket = nil
    assert_nothing_raised do
      bucket = Bucket.find(TEST_BUCKET)
    end
    
    assert bucket
    
    # Confirm we can fetch the bucket implicitly
    
    bucket = nil
    assert_nothing_raised do
      bucket = TestBucket.find
    end
    
    assert bucket
    
    # Confirm the bucket has the right name
    
    assert_equal TEST_BUCKET, bucket.name
    
    assert bucket.empty?
    assert_equal 0, bucket.size
    
    # Add some files to the bucket
    
    assert_nothing_raised do
      %w(a m z).each do |file_name|
        S3Object.create(file_name, file_name, bucket.name, :content_type => 'text/plain')
      end
    end
    
    # Confirm that we can reload the objects
    
    assert_nothing_raised do
      bucket.objects(:reload)
    end
    
    assert !bucket.empty?
    assert_equal 3, bucket.size
    
    assert_nothing_raised do
      bucket.objects(:marker => 'm')
    end

    assert_equal 1, bucket.size
    assert bucket['z']
    
    assert_equal 1, Bucket.find(TEST_BUCKET, :max_keys => 1).size
    
    assert_nothing_raised do
      bucket.objects(:reload)
    end
    
    assert_equal 3, bucket.size
    
    # Ensure the reloaded buckets have been repatriated
    
    assert_equal bucket, bucket.objects.first.bucket
    
    # Confirm that we can delete one of the objects and it will be removed
    
    object_to_be_deleted = bucket.objects.last
    assert_nothing_raised do
      object_to_be_deleted.delete
    end
    
    assert !bucket.objects.include?(object_to_be_deleted)
    
    # Confirm that we can add an object
    
    object = bucket.new_object(:value => 'hello')
    
    assert_raises(NoKeySpecified) do
      object.store
    end
    
    object.key = 'abc'
    assert_nothing_raised do
      object.store
    end
    
    assert bucket.objects.include?(object)
    
    # Confirm that the object is still there after reloading its objects
    
    assert_nothing_raised do
      bucket.objects(:reload)
    end 
    assert bucket.objects.include?(object)
    
    # Check that TestBucket has the same objects fetched implicitly
    
    assert_equal bucket.objects, TestBucket.objects
    
    # Empty out bucket
    
    assert_nothing_raised do
      bucket.delete_all
    end
    
    assert bucket.empty?
    
    bucket = nil
    assert_nothing_raised do
      bucket = Bucket.find(TEST_BUCKET)
    end
    
    assert bucket.empty?    
  end
  
  def test_bucket_name_is_switched_with_options_when_bucket_is_implicit_and_options_are_passed
    Object.const_set(:ImplicitlyNamedBucket, Class.new(Bucket))
    ImplicitlyNamedBucket.current_bucket = TEST_BUCKET
    assert ImplicitlyNamedBucket.objects.empty?
    
    %w(a b c).each {|key| S3Object.store(key, 'value does not matter', TEST_BUCKET)}
    
    assert_equal 3, ImplicitlyNamedBucket.objects.size
    
    objects = nil
    assert_nothing_raised do
      objects = ImplicitlyNamedBucket.objects(:max_keys => 1)
    end
    
    assert objects
    assert_equal 1, objects.size
  ensure
    %w(a b c).each {|key| S3Object.delete(key, TEST_BUCKET)}
  end
end