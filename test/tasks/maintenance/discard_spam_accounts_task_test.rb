# frozen_string_literal: true

require "test_helper"

class Maintenance::DiscardSpamAccountsTaskTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  test "#process discards a matching user" do
    user = create(:user, email: "spam@spammy-test.org", created_at: 1.day.ago, email_confirmed: false)

    Maintenance::DiscardSpamAccountsTask.process(user)

    assert_predicate user.reload, :discarded?
  end

  test "#process expires API keys" do
    user = create(:user, email: "spam@spammy-test.org", created_at: 1.day.ago, email_confirmed: false)
    api_key = create(:api_key, owner: user)

    Maintenance::DiscardSpamAccountsTask.process(user)

    assert_predicate api_key.reload, :expired?
  end

  test "#process destroys webhooks" do
    user = create(:user, email: "spam@spammy-test.org", created_at: 1.day.ago, email_confirmed: false)
    webhook = create(:global_web_hook, user: user)

    Maintenance::DiscardSpamAccountsTask.process(user)

    assert_not WebHook.exists?(webhook.id)
  end

  test "#process does not send a deletion complete email" do
    user = create(:user, email: "spam@spammy-test.org", created_at: 1.day.ago, email_confirmed: false)

    assert_no_enqueued_emails do
      Maintenance::DiscardSpamAccountsTask.process(user)
    end
  end

  test "#process restores deletion email callback after processing" do
    user = create(:user, email: "spam@spammy-test.org", created_at: 1.day.ago, email_confirmed: false)
    Maintenance::DiscardSpamAccountsTask.process(user)

    other_user = create(:user, email: "regular@spammy-test.org", created_at: 1.day.ago)

    assert_enqueued_emails 1 do
      other_user.discard!
    end
  end

  test "#process reports error when discard fails" do
    user = create(:user, email: "spam@spammy-test.org", created_at: 1.day.ago, email_confirmed: false)

    User.any_instance.expects(:yank_gems).raises(ActiveRecord::RecordNotDestroyed)

    assert_nothing_raised do
      Maintenance::DiscardSpamAccountsTask.process(user)
    end

    assert_not user.reload.discarded?
  end

  test "#process skips already discarded users" do
    user = create(:user, email: "spam@spammy-test.org", created_at: 1.day.ago, email_confirmed: false)
    user.discard!

    assert_no_changes -> { user.reload.deleted_at } do
      Maintenance::DiscardSpamAccountsTask.process(user)
    end
  end

  test "#collection only includes unconfirmed users matching domain with no gems in the date range" do
    task = Maintenance::DiscardSpamAccountsTask.new
    task.created_after = 3.days.ago
    task.created_before = 1.day.ago
    task.domain_suffix = "spammy-test.org"

    matching = create(:user, email: "recent@spammy-test.org", created_at: 2.days.ago, email_confirmed: false)
    too_recent = create(:user, email: "new@spammy-test.org", created_at: 1.hour.ago, email_confirmed: false)
    old_example = create(:user, email: "old@spammy-test.org", created_at: 5.days.ago, email_confirmed: false)
    other_domain = create(:user, email: "recent@anotherspammy-test.org", created_at: 2.days.ago, email_confirmed: false)
    confirmed = create(:user, email: "confirmed@spammy-test.org", created_at: 2.days.ago, email_confirmed: true)
    with_gems = create(:user, email: "gems@spammy-test.org", created_at: 2.days.ago, email_confirmed: false)
    create(:ownership, user: with_gems, rubygem: create(:rubygem))

    collection = task.collection

    assert_includes collection, matching
    assert_not_includes collection, too_recent
    assert_not_includes collection, old_example
    assert_not_includes collection, other_domain
    assert_not_includes collection, confirmed
    assert_not_includes collection, with_gems
  end

  test "#collection defaults created_before to now" do
    task = Maintenance::DiscardSpamAccountsTask.new
    task.created_after = 3.days.ago
    task.domain_suffix = "spammy-test.org"

    recent = create(:user, email: "just-now@spammy-test.org", created_at: 1.minute.ago, email_confirmed: false)

    assert_includes task.collection, recent
  end

  test "validates presence of created_after and domain_suffix" do
    task = Maintenance::DiscardSpamAccountsTask.new

    assert_not task.valid?
    assert_includes task.errors[:created_after], "can't be blank"
    assert_includes task.errors[:domain_suffix], "can't be blank"
  end
end
