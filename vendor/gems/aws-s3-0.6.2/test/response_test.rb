require File.dirname(__FILE__) + '/test_helper'
class BaseResponseTest < Test::Unit::TestCase 
  def setup
    @headers       = {'content-type' => 'text/plain', 'date' => Time.now}
    @response      = FakeResponse.new()
    @base_response = Base::Response.new(@response)
  end
  
  def test_status_predicates
    response = Proc.new {|code| Base::Response.new(FakeResponse.new(:code => code))}
    assert response[200].success?
    assert response[300].redirect?
    assert response[400].client_error?
    assert response[500].server_error?
  end
  
  def test_headers_passed_along_from_original_response
    assert_equal @response.headers, @base_response.headers
    assert_equal @response['date'], @base_response['date']
    original_headers, new_headers = {}, {}
    @response.headers.each {|k,v| original_headers[k] = v}
    @base_response.each {|k,v| new_headers[k] = v}
    assert_equal original_headers, new_headers
  end
end

class ErrorResponseTest < Test::Unit::TestCase
  def test_error_responses_are_always_in_error
    assert Error::Response.new(FakeResponse.new).error?
    assert Error::Response.new(FakeResponse.new(:code => 200)).error?
    assert Error::Response.new(FakeResponse.new(:headers => {'content-type' => 'text/plain'})).error?
  end
end

class S3ObjectResponseTest < Test::Unit::TestCase
  def test_etag_extracted
    mock_connection_for(S3Object, :returns => {:headers => {"etag" => %("acbd18db4cc2f85cedef654fccc4a4d8")}}).once
    object_response = S3Object.create('name_does_not_matter', 'data does not matter', 'bucket does not matter')
    assert_equal "acbd18db4cc2f85cedef654fccc4a4d8", object_response.etag 
  end
end

class ResponseClassFinderTest < Test::Unit::TestCase
  class CampfireBucket < Bucket
  end
  
  class BabyBase < Base
  end
  
  def test_on_base
    assert_equal Base::Response, FindResponseClass.for(Base)
    assert_equal Base::Response, FindResponseClass.for(AWS::S3::Base)
    
  end
  
  def test_on_subclass_with_corresponding_response_class
    assert_equal Bucket::Response, FindResponseClass.for(Bucket)
    assert_equal Bucket::Response, FindResponseClass.for(AWS::S3::Bucket)
  end
  
  def test_on_subclass_with_intermediary_parent_that_has_corresponding_response_class
    assert_equal Bucket::Response, FindResponseClass.for(CampfireBucket)
  end
  
  def test_on_subclass_with_no_corresponding_response_class_and_no_intermediary_parent
    assert_equal Base::Response, FindResponseClass.for(BabyBase)
  end
end