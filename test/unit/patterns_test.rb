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
    pending "regexp is not linear"

    assert Regexp.linear_time?(Patterns::URL_VALIDATION_REGEXP)
  end

  test "VERSION_PATTERN is linear" do
    pending "regexp is not linear"

    assert Regexp.linear_time?(Patterns::VERSION_PATTERN)
  end
end
