require File.dirname(__FILE__) + '/test_helper'

class ErrorTest < Test::Unit::TestCase
  def setup
    @container = AWS::S3
    @error = Error.new(Parsing::XmlParser.new(Fixtures::Errors.access_denied))
    @container.send(:remove_const, :NotImplemented) if @container.const_defined?(:NotImplemented)
  end
  
  def test_error_class_is_automatically_generated
    assert !@container.const_defined?('NotImplemented')
    error = Error.new(Parsing::XmlParser.new(Fixtures::Errors.not_implemented))
    assert @container.const_defined?('NotImplemented')
  end
  
  def test_error_contains_attributes
    assert_equal 'Access Denied', @error.message
  end
  
  def test_error_is_raisable_as_exception
    assert_raises(@container::AccessDenied) do
      @error.raise
    end
  end
  
  def test_error_message_is_passed_along_to_exception    
    @error.raise
  rescue @container::AccessDenied => e
    assert_equal 'Access Denied', e.message
  end
  
  def test_response_is_passed_along_to_exception
    response = Error::Response.new(FakeResponse.new(:code => 409, :body => Fixtures::Errors.access_denied))
    response.error.raise
  rescue @container::ResponseError => e
    assert e.response
    assert_kind_of Error::Response, e.response
    assert_equal response.error, e.response.error
  end
  
  def test_exception_class_clash
    assert !@container.const_defined?(:NotImplemented)
    # Create a class that does not inherit from exception that has the same name as the class
    # the Error instance is about to attempt to find or create
    @container.const_set(:NotImplemented, Class.new)
    assert @container.const_defined?(:NotImplemented)
    
    assert_raises(ExceptionClassClash) do
      Error.new(Parsing::XmlParser.new(Fixtures::Errors.not_implemented))
    end
  end
  
  def test_error_response_handles_attributes_with_no_value
    mock_connection_for(Bucket, :returns => {:body => Fixtures::Errors.error_with_no_message, :code => 500})
    
    begin
      Bucket.create('foo', 'invalid-argument' => 'bad juju')
    rescue ResponseError => error
    end
  
    assert_nothing_raised do
      error.response.error.message
    end
    assert_nil error.response.error.message
    
    assert_raises(NoMethodError) do
      error.response.error.non_existant_method
    end
  end
end