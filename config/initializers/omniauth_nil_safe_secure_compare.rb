# frozen_string_literal: true

# omniauth-oauth2 1.9.0's secure_compare calls bytesize on the stored state without
# a nil check, so a callback arriving without "omniauth.state" in the session (e.g.
# the same-site: strict cookie not being sent on the cross-site redirect from GitHub)
# raises NoMethodError instead of failing with :csrf_detected, bypassing the
# csrf_detected retry in FailureEndpoint (see omniauth.rb) and breaking admin login.
module NilSafeSecureCompare
  def secure_compare(string_a, string_b)
    return false if string_a.nil? || string_b.nil?
    super
  end
end

OmniAuth::Strategies::OAuth2.prepend(NilSafeSecureCompare)
