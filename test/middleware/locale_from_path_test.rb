# frozen_string_literal: true

require "test_helper"

class LocaleFromPathTest < ActiveSupport::TestCase
  setup do
    @captured_env = nil
    @app = lambda do |env|
      @captured_env = env.dup
      [200, {}, ["ok"]]
    end
    @middleware = Gemcutter::Middleware::LocaleFromPath.new(@app)
  end

  test "extracts a non-default locale from the path" do
    status, _headers, body = @middleware.call("PATH_INFO" => "/fr/gems/rails", "SCRIPT_NAME" => "")

    assert_equal 200, status
    assert_equal ["ok"], body
    assert_equal "fr", @captured_env["rubygems.locale"]
    assert_equal "/fr", @captured_env["SCRIPT_NAME"]
    assert_equal "/gems/rails", @captured_env["PATH_INFO"]
  end

  test "leaves paths without locales untouched" do
    status, _headers, body = @middleware.call("PATH_INFO" => "/gems/rails", "SCRIPT_NAME" => "")

    assert_equal 200, status
    assert_equal ["ok"], body
    assert_nil @captured_env["rubygems.locale"]
    assert_equal "", @captured_env["SCRIPT_NAME"]
    assert_equal "/gems/rails", @captured_env["PATH_INFO"]
  end

  test "redirects locale query params to locale paths" do
    status, headers, body = @middleware.call("PATH_INFO" => "/search", "QUERY_STRING" => "query=rails&locale=de", "SCRIPT_NAME" => "")

    assert_equal 301, status
    assert_equal "/de/search?query=rails", headers["Location"]
    assert_equal [], body
    assert_nil @captured_env
  end

  test "redirects default-locale query params to unprefixed paths" do
    status, headers, body = @middleware.call("PATH_INFO" => "/de/search", "QUERY_STRING" => "query=rails&locale=en", "SCRIPT_NAME" => "")

    assert_equal 301, status
    assert_equal "/search?query=rails", headers["Location"]
    assert_equal [], body
    assert_nil @captured_env
  end

  test "removes unsupported locale query params without changing the path locale" do
    status, headers, body = @middleware.call("PATH_INFO" => "/de/search", "QUERY_STRING" => "query=rails&locale=wat", "SCRIPT_NAME" => "")

    assert_equal 301, status
    assert_equal "/de/search?query=rails", headers["Location"]
    assert_equal [], body
    assert_nil @captured_env
  end

  test "redirects default-locale paths to unprefixed paths" do
    status, headers, body = @middleware.call("PATH_INFO" => "/en/pages/about", "QUERY_STRING" => "page=1", "SCRIPT_NAME" => "")

    assert_equal 301, status
    assert_equal "/pages/about?page=1", headers["Location"]
    assert_equal [], body
    assert_nil @captured_env
  end

  test "redirects the default-locale root to the unprefixed root" do
    status, headers, body = @middleware.call("PATH_INFO" => "/en", "SCRIPT_NAME" => "")

    assert_equal 301, status
    assert_equal "/", headers["Location"]
    assert_equal [], body
    assert_nil @captured_env
  end
end
