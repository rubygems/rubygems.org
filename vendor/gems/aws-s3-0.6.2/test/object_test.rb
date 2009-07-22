require File.dirname(__FILE__) + '/test_helper'

class ObjectTest < Test::Unit::TestCase
  def setup
    bucket  = Bucket.new(Parsing::XmlParser.new(Fixtures::Buckets.bucket_with_one_key))
    @object = bucket.objects.first
  end
  
  def test_header_settings_reader_and_writer
    headers = {'content-type' => 'text/plain'}
    mock_connection_for(S3Object, :returns => {:headers => headers})
    
    assert_nothing_raised do
      @object.content_type
    end
  
    assert_equal 'text/plain', @object.content_type
  
    assert_nothing_raised do
      @object.content_type = 'image/jpg'
    end
  
    assert_equal 'image/jpg', @object.content_type
  
    assert_raises(NoMethodError) do
      @object.non_existant_header_setting
    end
  end
  
  def test_key_name_validation
    assert_raises(InvalidKeyName) do
      S3Object.create(nil, '', 'marcel')
    end
    
    assert_raises(InvalidKeyName) do
      huge_name = 'a' * 1500
      S3Object.create(huge_name, '', 'marcel')
    end
  end
  
  def test_content_type_inference
    [
      ['foo.jpg',  {},                             'image/jpeg'],
      ['foo.txt',  {},                             'text/plain'],
      ['foo',      {},                             nil],
      ['foo.asdf', {},                             nil],
      ['foo.jpg',  {:content_type => nil},         nil],
      ['foo',      {:content_type => 'image/jpg'}, 'image/jpg'],
      ['foo.jpg',  {:content_type => 'image/png'}, 'image/png'],
      ['foo.asdf', {:content_type => 'image/jpg'}, 'image/jpg']
    ].each do |key, options, content_type|
      S3Object.send(:infer_content_type!, key, options)
      assert_equal content_type, options[:content_type]
    end
  end
  
  def test_object_has_owner
    assert_kind_of Owner, @object.owner 
  end
  
  def test_owner_attributes_are_accessible
    owner = @object.owner
    assert owner.id
    assert owner.display_name
    assert_equal 'bb2041a25975c3d4ce9775fe9e93e5b77a6a9fad97dc7e00686191f3790b13f1', owner.id
    assert_equal 'mmolina@onramp.net', owner.display_name
  end
  
  def test_only_valid_attributes_accessible
    assert_raises(NoMethodError) do
      @object.owner.foo
    end
  end
  
  def test_fetching_object_value_generates_value_object
    mock_connection_for(S3Object, :returns => {:body => 'hello!'})
    value = S3Object.value('foo', 'bar')
    assert_kind_of S3Object::Value, value
    assert_equal 'hello!', value
  end
  
  def test_fetching_file_by_name_raises_when_heuristic_fails
    mock_connection_for(Bucket, :returns => {:body => Fixtures::Buckets.bucket_with_one_key})
    assert_raises(NoSuchKey) do
      S3Object.find('not_tongue_overload.jpg', 'marcel_molina')
    end
    
    object = nil # Block scoping
    assert_nothing_raised do
      object = S3Object.find('tongue_overload.jpg', 'marcel_molina')
    end
    assert_kind_of S3Object, object
    assert_equal 'tongue_overload.jpg', object.key
  end
  
  def test_about
    headers = {'content-size' => '12345', 'date' => Time.now.httpdate, 'content-type' => 'application/xml'}
    mock_connection_for(S3Object, :returns => [
      {:headers => headers},
      {:code    => 404}
      ]
    )
    about = S3Object.about('foo', 'bar')
    assert_kind_of S3Object::About, about
    assert_equal headers, about
    
    assert_raises(NoSuchKey) do
      S3Object.about('foo', 'bar')
    end
  end
  
  def test_can_tell_that_an_s3object_does_not_exist
    mock_connection_for(S3Object, :returns => {:code => 404})
    assert_equal false, S3Object.exists?('foo', 'bar')
  end
  
  def test_can_tell_that_an_s3object_exists
    mock_connection_for(S3Object, :returns => {:code => 200})
    assert_equal true, S3Object.exists?('foo', 'bar')
  end
  
  def test_s3object_equality
    mock_connection_for(Bucket, :returns => {:body => Fixtures::Buckets.bucket_with_more_than_one_key})
    file1, file2 = Bucket.objects('does not matter')
    assert file1 == file1
    assert file2 == file2
    assert !(file1 == file2) # /!\ Parens required /!\
  end
  
  def test_inspect
    mock_connection_for(Bucket, :returns => {:body => Fixtures::Buckets.bucket_with_one_key})
    object = S3Object.find('tongue_overload.jpg', 'bucket does not matter')
    assert object.path
    assert_nothing_raised { object.inspect }
    assert object.inspect[object.path]
  end
 
  def test_etag
    mock_connection_for(Bucket, :returns => {:body => Fixtures::Buckets.bucket_with_one_key})
    file = S3Object.find('tongue_overload.jpg', 'bucket does not matter')
    assert file.etag
    assert_equal 'f21f7c4e8ea6e34b268887b07d6da745', file.etag
  end
 
  def test_fetching_information_about_an_object_that_does_not_exist_raises_no_such_key
    mock_connection_for(S3Object, :returns => {:body => '', :code => 404})
    assert_raises(NoSuchKey) do
      S3Object.about('asdfasdfasdfas-this-does-not-exist', 'bucket does not matter')
    end
  end
end

class MetadataTest < Test::Unit::TestCase
  def setup
    @metadata = S3Object::Metadata.new(Fixtures::Headers.headers_including_one_piece_of_metadata)
  end
    
  def test_only_metadata_is_extracted
    assert @metadata.to_headers.size == 1
    assert @metadata.to_headers['x-amz-meta-test']
    assert_equal 'foo', @metadata.to_headers['x-amz-meta-test']
  end
  
  def test_setting_new_metadata_normalizes_name
    @metadata[:bar] = 'baz'
    assert @metadata.to_headers.include?('x-amz-meta-bar')
    @metadata['baz'] = 'quux'
    assert @metadata.to_headers.include?('x-amz-meta-baz')
    @metadata['x-amz-meta-quux'] = 'whatever'
    assert @metadata.to_headers.include?('x-amz-meta-quux')
  end
  
  def test_clobbering_existing_header
    @metadata[:bar] = 'baz'
    assert_equal 'baz', @metadata.to_headers['x-amz-meta-bar']
    @metadata[:bar] = 'quux'
    assert_equal 'quux', @metadata.to_headers['x-amz-meta-bar']
    @metadata['bar'] = 'foo'
    assert_equal 'foo', @metadata.to_headers['x-amz-meta-bar']
    @metadata['x-amz-meta-bar'] = 'bar'
    assert_equal 'bar', @metadata.to_headers['x-amz-meta-bar']
  end
  
  def test_invalid_metadata
    @metadata[:invalid_header] = ' ' * (S3Object::Metadata::SIZE_LIMIT + 1)
    assert_raises InvalidMetadataValue do
      @metadata.to_headers
    end
  end
end

class ValueTest < Test::Unit::TestCase
  def setup
    @response = FakeResponse.new(:body => 'hello there')
    @value    = S3Object::Value.new(@response)
  end
  
  def test_value_is_set_to_response_body
    assert_equal @response.body, @value
  end
  
  def test_response_is_accessible_from_value_object
    assert_equal @response, @value.response
  end
end