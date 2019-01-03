# frozen_string_literal: true

require 'test_helper'

class EncodingTest < ActionDispatch::IntegrationTest
  test "invalid utf-8 characters should be sanitized" do
    get "/api/v1/dependencies?gems=vagrant,vagrant-login,vagrant-share,vagrant%ADvbguest"
    assert_response :success
  end

  test "gzip not supported" do
    get '/'
    assert_response :success
    assert_nil @response.headers['Content-Encoding']
  end
end
