require "test_helper"

class Types::DurationTest < ActiveSupport::TestCase
  setup do
    @type = Types::Duration.new
  end

  test "deserialize iso8601" do
    assert_equal 15.minutes, @type.deserialize("PT15M")
  end

  test "deserialize seconds as string" do
    assert_equal 300.seconds, @type.deserialize("300")
  end

  test "deserialize duration" do
    assert_equal 300.seconds, @type.deserialize(300.seconds)
  end

  test "deserialize unsupported value" do
    assert_raise { @type.deserialize(Object.new) }
  end

  test "deserialize unsupported string" do
    assert_nil @type.deserialize("random string")
  end

  test "serialize duration" do
    assert_equal "P1D", @type.serialize(1.day)
  end

  test "type_cast_for_schema" do
    assert_equal '"P1D"', @type.type_cast_for_schema(1.day)
  end
end
