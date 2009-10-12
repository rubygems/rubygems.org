require 'test/unit'
require 'uri'
$:.unshift File.dirname(__FILE__) + '/../../lib'
require 'aws/s3'
begin
  require_library_or_gem 'breakpoint'
rescue LoadError
end

TEST_BUCKET = 'aws-s3-tests'
TEST_FILE   = File.dirname(__FILE__) + '/test_file.data'

class Test::Unit::TestCase
  include AWS::S3
  def establish_real_connection
    Base.establish_connection!(
      :access_key_id     => ENV['AMAZON_ACCESS_KEY_ID'], 
      :secret_access_key => ENV['AMAZON_SECRET_ACCESS_KEY']
    )
  end
  
  def disconnect!
    Base.disconnect
  end
  
  class TestBucket < Bucket
    set_current_bucket_to TEST_BUCKET
  end
  
  class TestS3Object < S3Object
    set_current_bucket_to TEST_BUCKET
  end
end