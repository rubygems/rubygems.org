require "application_system_test_case"

class WebAuthnVerificationTest < ApplicationSystemTestCase
  setup do
    @user = create(:user)
    create_webauthn_credential
    @verification = create(:webauthn_verification, user: @user)
    @port = 5678
    @mock_client = MockClientServer.new(@port)
  end

  test "when verifying webauthn credential" do
    visit webauthn_verification_path(webauthn_token: @verification.path_token, params: { port: @port })
    WebAuthn::AuthenticatorAssertionResponse.any_instance.stubs(:verify).returns true

    assert_match "Authenticate with Security Device", page.html
    assert_match "Authenticating as #{@user.handle}", page.html

    click_on "Authenticate"

    assert redirect_to("http://localhost:#{@port}?code=#{@verification.otp}")
    assert redirect_to(successful_verification_webauthn_verification_path)
    assert page.has_content?("Success!")
    assert_link_is_expired
  end

  test "when verifying webauthn and not using safari" do
    visit webauthn_verification_path(webauthn_token: @verification.path_token, params: { port: @port })
    WebAuthn::AuthenticatorAssertionResponse.any_instance.stubs(:verify).returns true

    refute_match "It looks like you are using Safari. Due to limitations within Safari, " \
                 "you will be unable to authenticate using this browser. Please use a different browser. " \
                 'Refer to the <a target="_blank" href="https://guides.rubygems.org/using-webauthn-mfa-in-command-line">' \
                 "WebAuthn MFA CLI guide</a> for more information on this limitation.",
      page.html
  end

  test "when verifying webauthn and using safari" do
    Capybara.current_driver = :fake_safari
    visit webauthn_verification_path(webauthn_token: @verification.path_token, params: { port: @port })
    WebAuthn::AuthenticatorAssertionResponse.any_instance.stubs(:verify).returns true

    assert_match "It looks like you are using Safari. Due to limitations within Safari, " \
                 "you will be unable to authenticate using this browser. Please use a different browser. " \
                 'Refer to the <a target="_blank" href="https://guides.rubygems.org/using-webauthn-mfa-in-command-line">' \
                 "WebAuthn MFA CLI guide</a> for more information on this limitation.",
      page.html
  end

  test "when client closes connection during verification" do
    visit webauthn_verification_path(webauthn_token: @verification.path_token, params: { port: @port })
    WebAuthn::AuthenticatorAssertionResponse.any_instance.stubs(:verify).returns true

    assert_match "Authenticate with Security Device", page.html
    assert_match "Authenticating as #{@user.handle}", page.html

    @mock_client.kill_server
    click_on "Authenticate"

    assert redirect_to("http://localhost:#{@port}?code=#{@verification.otp}")
    assert redirect_to(failed_verification_webauthn_verification_path)
    assert page.has_content?("Please close this browser and try again.")
    assert_link_is_expired
  end

  test "when port given does not match the client port" do
    wrong_port = 1111
    visit webauthn_verification_path(webauthn_token: @verification.path_token, params: { port: wrong_port })
    WebAuthn::AuthenticatorAssertionResponse.any_instance.stubs(:verify).returns true

    assert_match "Authenticate with Security Device", page.html
    assert_match "Authenticating as #{@user.handle}", page.html

    click_on "Authenticate"

    assert redirect_to("http://localhost:#{wrong_port}?code=#{@verification.otp}")
    assert redirect_to(failed_verification_webauthn_verification_path)
    assert page.has_content?("Please close this browser and try again.")
    assert_link_is_expired
  end

  test "when there is a client error" do
    @mock_client.response = @mock_client.bad_request_response
    visit webauthn_verification_path(webauthn_token: @verification.path_token, params: { port: @port })
    WebAuthn::AuthenticatorAssertionResponse.any_instance.stubs(:verify).returns true

    assert_match "Authenticate with Security Device", page.html
    assert_match "Authenticating as #{@user.handle}", page.html

    click_on "Authenticate"

    assert redirect_to(failed_verification_webauthn_verification_path)
    assert page.has_content?("Please close this browser and try again.")
    assert_link_is_expired
  end

  def teardown
    @mock_client.kill_server
    @authenticator.remove!
  end

  private

  def assert_link_is_expired
    visit webauthn_verification_path(webauthn_token: @verification.path_token, params: { port: @port })

    assert page.has_content?("The token in the link you used has either expired or been used already.")
  end

  class MockClientServer
    attr_writer :response

    def initialize(port)
      @port = port
      @server = TCPServer.new(@port)
      @response = success_response
      create_socket
    end

    def create_socket
      @thread = Thread.new do
        loop do
          socket = @server.accept
          request_line = socket.gets

          method, _req_uri, _protocol = request_line.split
          if method == "OPTIONS"
            socket.print options_response
            socket.close
            next # will be GET
          else
            socket.print @response
            socket.close
            break
          end
        end
      ensure
        @server.close
      end
      @thread.abort_on_exception = true
      @thread.report_on_exception = false
    end

    def kill_server
      Thread.kill(@thread)
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

    def success_response
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
end
