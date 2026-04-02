# frozen_string_literal: true

require "test_helper"

class Types::JsonDeserializableTest < ActiveSupport::TestCase
  class DummyArray < Array
    def as_json(*)
      { "unexpected" => "structure" }
    end
  end

  setup do
    @type = Types::JsonDeserializable.new(DummyArray)
  end

  test "cast_value with nil" do
    assert_nil @type.cast_value(nil)
  end

  test "cast_value with instance of klass" do
    instance = DummyArray.new([1, 2, 3])

    result = @type.cast_value(instance)

    assert_equal instance, result
    assert_instance_of DummyArray, result
  end

  test "cast_value with raw data" do
    raw_data = [1, 2, 3]
    expected = DummyArray.new(raw_data)

    result = @type.cast_value(raw_data)

    assert_equal expected, result
    assert_instance_of DummyArray, result
  end

  test "deserialize parses JSON and casts to klass" do
    json_string = "[1,2,3]"
    expected = DummyArray.new([1, 2, 3])

    result = @type.deserialize(json_string)

    assert_equal expected, result
    assert_instance_of DummyArray, result
  end
end
