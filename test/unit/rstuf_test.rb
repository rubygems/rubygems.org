require "test_helper"

class RstufTest < ActiveSupport::TestCase
  def setup
    @original_base_url = Rstuf.base_url
    @original_enabled = Rstuf.enabled
    @original_wait_for = Rstuf.wait_for
  end

  def teardown
    Rstuf.base_url = @original_base_url
    Rstuf.enabled = @original_enabled
    Rstuf.wait_for = @original_wait_for
  end

  test "default values are set correctly" do
    refute Rstuf.enabled
    assert_equal 1, Rstuf.wait_for
  end

  test "base_url can be set and retrieved" do
    new_url = "http://example.com"
    Rstuf.base_url = new_url

    assert_equal new_url, Rstuf.base_url
  end

  test "enabled can be set and retrieved" do
    Rstuf.enabled = true

    assert Rstuf.enabled
  end

  test "enabled? returns the value of enabled" do
    Rstuf.enabled = false

    refute_predicate Rstuf, :enabled?
    Rstuf.enabled = true

    assert_predicate Rstuf, :enabled?
  end

  test "wait_for can be set and retrieved" do
    new_wait = 5
    Rstuf.wait_for = new_wait

    assert_equal new_wait, Rstuf.wait_for
  end
end
