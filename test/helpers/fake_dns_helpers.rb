# frozen_string_literal: true

require "helpers/fake_dns_resolver"

module FakeDnsHelpers
  # Routes every default-resolver lookup in the app (Resolv::DNS.new) to `resolver`.
  def stub_dns(resolver = FakeDnsResolver.new)
    Resolv::DNS.stubs(:new).returns(resolver)
    resolver
  end
end
