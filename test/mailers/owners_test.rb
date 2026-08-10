# frozen_string_literal: true

require "test_helper"

class OwnersMailerTest < ActionMailer::TestCase
  include Rails.application.routes.url_helpers

  setup do
    @owner = create(:user)
    @maintainer = create(:user)
    @rubygem = create(:rubygem, name: "test-gem")
    @owner_ownership = create(:ownership, rubygem: @rubygem, user: @owner)
    @maintainer_ownership = create(:ownership, rubygem: @rubygem, user: @maintainer)
  end

  context "#owner_updated" do
    should "include host in subject" do
      email = OwnersMailer.with(ownership: @maintainer_ownership).owner_updated

      assert_emails(1) { email.deliver_now }
      assert_equal email.subject, "Your role was updated for the #{@rubygem.name} gem"
    end
  end

  context "#ownership_confirmation" do
    should "render the confirmation link as a button" do
      ownership = create(:ownership, :unconfirmed, rubygem: @rubygem)
      OwnersMailer.ownership_confirmation(ownership).deliver_now

      assert_cta_button confirm_rubygem_owners_url(@rubygem.slug, token: ownership.token, host: Gemcutter::HOST), "VERIFY"
    end
  end
end
