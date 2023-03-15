require "application_system_test_case"

class WebAuthnVerificationTest < ApplicationSystemTestCase
  setup do
    @user = create(:user)
    create_webauthn_credential
    @verification = create(:webauthn_verification, user: @user)
    @port = 5678
  end

  test "when verifying webauthn credential" do
    create_localhost_server
    visit webauthn_verification_path(webauthn_token: @verification.path_token, params: {port: @port})
    WebAuthn::AuthenticatorAssertionResponse.any_instance.stubs(:verify).returns true

    assert_match "Authenticate with Security Device", page.html
    assert_match "Authenticating as #{@user.handle}", page.html

    click_on "Authenticate"

    assert redirect_to("http://localhost:#{@port}?code=#{@verification.otp}")
    assert redirect_to(successful_verification_webauthn_verification_path)
    assert page.has_content?("Success!")
  end

  test "when client closes connection during verification" do
    create_localhost_server
    visit webauthn_verification_path(webauthn_token: @verification.path_token, params: {port: @port})
    WebAuthn::AuthenticatorAssertionResponse.any_instance.stubs(:verify).returns true

    assert_match "Authenticate with Security Device", page.html
    assert_match "Authenticating as #{@user.handle}", page.html

    Thread.kill(@thread)
    click_on "Authenticate"

    assert redirect_to("http://localhost:#{@port}?code=#{@verification.otp}")
    assert redirect_to(failed_verification_webauthn_verification_path)
    assert page.has_content?("Please close this browser and try again.")
  end

  test "when port given does not match the client port" do
    create_localhost_server
    wrong_port = 1111
    visit webauthn_verification_path(webauthn_token: @verification.path_token, params: {port: wrong_port})
    WebAuthn::AuthenticatorAssertionResponse.any_instance.stubs(:verify).returns true

    assert_match "Authenticate with Security Device", page.html
    assert_match "Authenticating as #{@user.handle}", page.html

    click_on "Authenticate"

    assert redirect_to("http://localhost:#{wrong_port}?code=#{@verification.otp}")
    assert redirect_to(failed_verification_webauthn_verification_path)
    assert page.has_content?("Please close this browser and try again.")
  end

  test "when there is a client error" do
    create_localhost_server(res: bad_request_response)
    visit webauthn_verification_path(webauthn_token: @verification.path_token, params: {port: @port})
    WebAuthn::AuthenticatorAssertionResponse.any_instance.stubs(:verify).returns true

    assert_match "Authenticate with Security Device", page.html
    assert_match "Authenticating as #{@user.handle}", page.html

    click_on "Authenticate"

    assert redirect_to(failed_verification_webauthn_verification_path)
    assert page.has_content?("Please close this browser and try again.")
  end

  def teardown
    Thread.kill(@thread)
    @authenticator.remove!
  end

  def create_localhost_server(res: get_response)
    server = TCPServer.new(@port)
    @thread = Thread.new do
      loop do
        socket = server.accept
        request_line = socket.gets

        method, req_uri, _protocol = request_line.split(" ")
        if method.upcase == "OPTIONS"
          socket.print options_response
          socket.close
          next # will be GET
        else
          socket.print res
          socket.close
          break
        end
      end
    ensure
      server.close
    end
    @thread.abort_on_exception = true
    @thread.report_on_exception = false
  end

  def options_response
    <<~RESPONSE
      HTTP/1.1 204 No Content\r
      connection: close\r
      access-control-allow-origin: *\r
      access-control-allow-methods: POST\r
      access-control-allow-headers: Content-Type, Authorization, x-csrf-token\r
      \r
    RESPONSE
  end

  def get_response
    <<~RESPONSE
      HTTP/1.1 200 OK\r
      connection: close\r
      access-control-allow-origin: *\r
      access-control-allow-methods: POST\r
      access-control-allow-headers: Content-Type, Authorization, x-csrf-token\r
      content-type: text/plain\r
      content-length: 7\r
      \r
      success
    RESPONSE
  end

  def bad_request_response
    <<~RESPONSE
      HTTP/1.1 400 Bad Request\r
      connection: close\r
      access-control-allow-origin: rubygems.example\r
      access-control-allow-methods: POST\r
      access-control-allow-headers: Content-Type, Authorization, x-csrf-token\r
      content-type: text/plain\r
      content-length: 22\r
      \r
      missing code parameter
    RESPONSE
  end
end
