# frozen_string_literal: true

require "digest"
require "webmock"

module PasswordHelpers
  SECURE_TEST_PASSWORD = "?98,TUESDAY,SHOWN,exactly,56?"
  COMPROMISED_TEST_PASSWORD = "password1234"

  # Stubs the HIBP k-anonymity API (via WebMock) to report the given password as breached.
  # The Pwned gem sends the first 5 hex chars of the SHA-1 hash to the HIBP range endpoint
  # and checks if the remaining suffix appears in the response body.
  def stub_password_as_compromised(password)
    sha1 = Digest::SHA1.hexdigest(password).upcase
    prefix = sha1[0..4]
    suffix = sha1[5..]

    WebMock::API.stub_request(:get, "https://api.pwnedpasswords.com/range/#{prefix}")
      .to_return(status: 200, body: "#{suffix}:5\r\n")
  end
end
