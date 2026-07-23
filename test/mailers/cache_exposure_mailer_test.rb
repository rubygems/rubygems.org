# frozen_string_literal: true

require "test_helper"

class CacheExposureMailerTest < ActionMailer::TestCase
  include ActiveJob::TestHelper

  setup do
    @user = create(:user)
  end

  context "#cache_exposure_notice" do
    should "render and deliver to the user with the host in the subject" do
      email = CacheExposureMailer.cache_exposure_notice(@user)

      # deliver_now renders the template, so this also guards against ERB errors.
      assert_emails(1) { email.deliver_now }

      assert_equal [@user.email], email.to
      # Default DKIM/SPF-aligned sender (Gemcutter::MAIL_SENDER) for DMARC; replies to support.
      assert_equal [Mail::Address.new(Gemcutter::MAIL_SENDER).address], email.from
      assert_equal ["support@rubygems.org"], email.reply_to
      assert_includes email.subject, Gemcutter::HOST_DISPLAY
    end

    should "deliver both an html and a text/plain part" do
      email = CacheExposureMailer.cache_exposure_notice(@user)

      assert_predicate email, :multipart?
      assert_not_nil email.html_part
      assert_not_nil email.text_part
      # decoded unwraps the transfer encoding, so this is robust to quoted-printable.
      assert_includes email.html_part.decoded, "has been expired"
      assert_includes email.text_part.decoded, "has been expired"
    end

    should "record an EMAIL_SENT event carrying this notice's action AND mailer" do
      # The notify task de-dupes on both fields (see NOTICE_MAILER_ACTION / _NAME), so
      # assert record_delivery persists both and that the constants match what it writes.
      events = @user.events.where(tag: Events::UserEvent::EMAIL_SENT)
        .where("additional ->> 'action' = ?", Maintenance::NotifyCacheExposedUsersTask::NOTICE_MAILER_ACTION)
        .where("additional ->> 'mailer' = ?", Maintenance::NotifyCacheExposedUsersTask::NOTICE_MAILER_NAME)

      assert_difference -> { events.count }, 1 do
        CacheExposureMailer.cache_exposure_notice(@user).deliver_now
      end
    end

    should "enqueue delivery via the custom job on the dedicated within_24_hours queue" do
      # The dedicated queue keeps the bulk notices off the transactional mailers queue.
      assert_enqueued_with(job: CacheExposureMailDeliveryJob, queue: "within_24_hours") do
        CacheExposureMailer.cache_exposure_notice(@user).deliver_later
      end
    end

    should "carry the incident-critical recovery and cohort guidance in both parts" do
      email = CacheExposureMailer.cache_exposure_notice(@user)
      html = email.html_part.decoded
      text = email.text_part.decoded

      # The recovery and cohort claims a recipient must be able to act on; assert them so
      # an accidental copy change or revert is caught. Each is chosen to appear verbatim in
      # the HTML too (no <strong> boundary splits).
      [
        "as part of a security incident",                # cohort framing
        "Installing and downloading gems is unaffected", # impact framing
        "GET /api/v1/api_key",                           # the leaky pathway
        "gem signout",                                   # recovery: clear the stored key
        "gem signin",                                    # recovery: sign in again for a fresh key
        "blog.rubygems.org",                             # official blog link
        "verify it independently",                       # verify-the-email-independently framing
        "has now been retired"                           # the sign-in endpoint is gone
      ].each do |snippet|
        assert_includes html, snippet, "HTML part missing: #{snippet}"
        assert_includes text, snippet, "text part missing: #{snippet}"
      end
    end
  end

  context "#cache_exposure_inactive_notice" do
    should "render and deliver from the aligned sender with support reply-to and host in subject" do
      email = CacheExposureMailer.cache_exposure_inactive_notice(@user)

      # deliver_now renders both templates, so this also guards against ERB errors.
      assert_emails(1) { email.deliver_now }

      assert_equal [@user.email], email.to
      assert_equal [Mail::Address.new(Gemcutter::MAIL_SENDER).address], email.from
      assert_equal ["support@rubygems.org"], email.reply_to
      assert_includes email.subject, Gemcutter::HOST_DISPLAY
    end

    should "record an EMAIL_SENT event under its OWN action, distinct from the active notice" do
      # The inactive task de-dupes on these fields; a distinct action keeps the two notices'
      # dedup independent (receiving one must not suppress the other).
      events = @user.events.where(tag: Events::UserEvent::EMAIL_SENT)
        .where("additional ->> 'action' = ?", Maintenance::NotifyCacheExposedInactiveUsersTask::NOTICE_MAILER_ACTION)
        .where("additional ->> 'mailer' = ?", Maintenance::NotifyCacheExposedInactiveUsersTask::NOTICE_MAILER_NAME)

      assert_difference -> { events.count }, 1 do
        CacheExposureMailer.cache_exposure_inactive_notice(@user).deliver_now
      end
    end

    should "carry the inactive-cohort framing, and NOT the active-cohort credential remediation" do
      email = CacheExposureMailer.cache_exposure_inactive_notice(@user)
      html = email.html_part.decoded
      text = email.text_part.decoded

      ["already inactive", "No credential action is needed", "blog.rubygems.org", "GHSA-9j48-x3c3-mrp2", "review"].each do |snippet|
        assert_includes html, snippet, "HTML part missing: #{snippet}"
        assert_includes text, snippet, "text part missing: #{snippet}"
      end
      # This cohort's key is already dead: no credential action. They must NOT be told their key
      # was just expired or to clear/replace credentials or sign in — that copy is active-only.
      ["your next push will fail", "gem signout", "gem signin"].each do |snippet|
        refute_includes html, snippet, "inactive notice must not carry active-cohort remediation: #{snippet}"
        refute_includes text, snippet, "inactive notice must not carry active-cohort remediation: #{snippet}"
      end
    end
  end
end
