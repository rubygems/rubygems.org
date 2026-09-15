# frozen_string_literal: true

class Current < ActiveSupport::CurrentAttributes
  attribute :request
  attribute :user
  # The ApiKey that authenticated this request, if any.
  attribute :api_key
  # The principal a key is being issued to when no key has authenticated the
  # request yet (OIDC trusted publisher token exchange).
  attribute :api_key_owner
end
