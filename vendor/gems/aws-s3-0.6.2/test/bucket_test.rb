require File.dirname(__FILE__) + '/test_helper'

class BucketTest < Test::Unit::TestCase  
  def test_bucket_name_validation
    valid_names   = %w(123 joe step-one step_two step3 step_4 step-5 step.six)
    invalid_names = ['12', 'jo', 'kevin spacey', 'larry@wall', '', 'a' * 256]
    validate_name = Proc.new {|name| Bucket.send(:validate_name!, name)}
    valid_names.each do |valid_name|
      assert_nothing_raised { validate_name[valid_name] }
    end
    
    invalid_names.each do |invalid_name|
      assert_raises(InvalidBucketName) { validate_name[invalid_name] }
    end
  end
  
  def test_empty_bucket
    mock_connection_for(Bucket, :returns => {:body => Fixtures::Buckets.empty_bucket, :code => 200})
    bucket = Bucket.find('marcel_molina')
    assert bucket.empty?
  end
  
  def test_bucket_with_one_file
    mock_connection_for(Bucket, :returns => {:body => Fixtures::Buckets.bucket_with_one_key, :code => 200})
    bucket = Bucket.find('marcel_molina')
    assert !bucket.empty?
    assert_equal 1, bucket.size
    assert_equal %w(tongue_overload.jpg), bucket.objects.map {|object| object.key}
    assert bucket['tongue_overload.jpg']
  end
  
  def test_bucket_with_more_than_one_file
    mock_connection_for(Bucket, :returns => {:body => Fixtures::Buckets.bucket_with_more_than_one_key, :code => 200})
    bucket = Bucket.find('marcel_molina')
    assert !bucket.empty?
    assert_equal 2, bucket.size
    assert_equal %w(beluga_baby.jpg tongue_overload.jpg), bucket.objects.map {|object| object.key}.sort
    assert bucket['tongue_overload.jpg']
  end
  
  def test_bucket_path
    assert_equal '/bucket_name?max-keys=2', Bucket.send(:path, 'bucket_name', :max_keys => 2)
    assert_equal '/bucket_name', Bucket.send(:path, 'bucket_name', {})    
  end
  
  def test_should_not_be_truncated
    mock_connection_for(Bucket, :returns => {:body => Fixtures::Buckets.bucket_with_more_than_one_key, :code => 200})
    bucket = Bucket.find('marcel_molina')
    assert !bucket.is_truncated
  end
  
  def test_should_be_truncated
    mock_connection_for(Bucket, :returns => {:body => Fixtures::Buckets.truncated_bucket_with_more_than_one_key, :code => 200})
    bucket = Bucket.find('marcel_molina')
    assert bucket.is_truncated    
  end
  
  def test_bucket_name_should_have_leading_slash_prepended_only_once_when_forcing_a_delete
    # References bug: http://rubyforge.org/tracker/index.php?func=detail&aid=19158&group_id=2409&atid=9356
    bucket_name          = 'foo'
    expected_bucket_path = "/#{bucket_name}"
    
    mock_bucket = flexmock('Mock bucket') do |mock|
      mock.should_receive(:delete_all).once
    end
    mock_response = flexmock('Mock delete response') do |mock|
      mock.should_receive(:success?).once
    end
    
    flexmock(Bucket).should_receive(:find).with(bucket_name).once.and_return(mock_bucket)
    flexmock(Base).should_receive(:delete).with(expected_bucket_path).once.and_return(mock_response)
    Bucket.delete(bucket_name, :force => true)
  end
end