require File.dirname(__FILE__) + '/test_helper'

class TypecastingTest < Test::Unit::TestCase
  # Make it easier to call methods in tests
  Parsing::Typecasting.public_instance_methods.each do |method|
    Parsing::Typecasting.send(:module_function, method)
  end
  
  def test_array_with_one_element_that_is_a_hash
    value = [{'Available' => 'true'}]
    assert_equal [{'available' => true}], Parsing::Typecasting.typecast(value)
  end
  
  def test_hash_with_one_key_whose_value_is_an_array
    value = {
      'Bucket' => 
        [ 
          {'Available' => 'true'} 
        ] 
    }
    
    expected = {
      'bucket' => 
        [
          {'available' => true}
        ]
    }
    assert_equal expected, Parsing::Typecasting.typecast(value)
  end
  
end

class XmlParserTest < Test::Unit::TestCase
  def test_bucket_is_always_forced_to_be_an_array_unless_empty
    one_bucket    = Parsing::XmlParser.new(Fixtures::Buckets.bucket_list_with_one_bucket)
    more_than_one = Parsing::XmlParser.new(Fixtures::Buckets.bucket_list_with_more_than_one_bucket)
    
    [one_bucket, more_than_one].each do |bucket_list|
      assert_kind_of Array, bucket_list['buckets']['bucket']
    end
    
    no_buckets    = Parsing::XmlParser.new(Fixtures::Buckets.empty_bucket_list)
    assert no_buckets.has_key?('buckets')
    assert_nil no_buckets['buckets']
  end
  
  def test_bucket_contents_are_forced_to_be_an_array_unless_empty
    one_key       = Parsing::XmlParser.new(Fixtures::Buckets.bucket_with_one_key)
    more_than_one = Parsing::XmlParser.new(Fixtures::Buckets.bucket_with_more_than_one_key)
    [one_key, more_than_one].each do |bucket_with_contents|
      assert_kind_of Array, bucket_with_contents['contents']
    end
    
    no_keys = Parsing::XmlParser.new(Fixtures::Buckets.empty_bucket)
    assert !no_keys.has_key?('contents')
  end
  
  def test_policy_grants_are_always_an_array
    policy = Parsing::XmlParser.new(Fixtures::Policies.policy_with_one_grant)
    assert_kind_of Array, policy['access_control_list']['grant']
  end
  
  def test_empty_xml_response_is_not_parsed
    assert_equal({}, Parsing::XmlParser.new(''))
  end
end