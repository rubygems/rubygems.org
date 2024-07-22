# frozen_string_literal: true

require "test_helper"

class PatternsTest < ActiveSupport::TestCase
  test "JAVA_HTTP_USER_AGENT is linear" do
    assert Regexp.linear_time?(Patterns::JAVA_HTTP_USER_AGENT)
  end

  test "ROUTE_PATTERN is linear" do
    assert Regexp.linear_time?(Patterns::ROUTE_PATTERN)
  end

  test "LAZY_ROUTE_PATTERN is linear" do
    assert Regexp.linear_time?(Patterns::LAZY_ROUTE_PATTERN)
  end

  test "NAME_PATTERN is linear" do
    assert Regexp.linear_time?(Patterns::NAME_PATTERN)
  end

  test "URL_VALIDATION_REGEXP is linear" do
    skip "regexp is not linear"

    assert Regexp.linear_time?(Patterns::URL_VALIDATION_REGEXP)
  end

  test "VERSION_PATTERN is linear" do
    skip "regexp is not linear"

    assert Regexp.linear_time?(Patterns::VERSION_PATTERN)
  end

  test "REQUIREMENT_PATTERN is linear" do
    skip "regexp is not linear"

    assert Regexp.linear_time?(Patterns::REQUIREMENT_PATTERN)
  end

  test "LETTER_REGEXP is linear" do
    assert Regexp.linear_time?(Patterns::LETTER_REGEXP)
  end

  test "SPECIAL_CHAR_PREFIX_REGEXP is linear" do
    assert Regexp.linear_time?(Patterns::SPECIAL_CHAR_PREFIX_REGEXP)
  end

  test "BASE64_SHA256_PATTERN is linear" do
    assert Regexp.linear_time?(Patterns::BASE64_SHA256_PATTERN)
  end
end
