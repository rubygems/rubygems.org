require "test_helper"

class OwnersMailerTest < ActionMailer::TestCase
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
      assert_equal email.subject, "Your role was updated for #{@rubygem.name} gem"
    end
  end
end
