# frozen_string_literal: true

require "test_helper"

class UnblockEmailDomainTest < ActiveSupport::TestCase
  should "refuse to destroy an upstream-sourced row even when invoked directly" do
    upstream = create(:blocked_email_domain, :upstream, domain: "upstream.example.test-domain.io")
    admin = create(:admin_github_user, :is_admin)
    action = Avo::Actions::UnblockEmailDomain.new

    action.handle(
      current_user: admin,
      resource: nil,
      records: [upstream],
      fields: { comment: "Attempting to bypass the UI visibility guard" },
      query: nil
    )

    assert_includes action.response[:messages].first[:body], "Refusing to unblock upstream-sourced row"
    assert BlockedEmailDomain.exists?(id: upstream.id),
      "upstream row must survive even when the action handler is invoked directly"
  end
end
