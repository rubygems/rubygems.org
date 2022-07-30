require "test_helper"

class MailerTest < ActiveSupport::TestCase
  MIN_DOWNLOADS_FOR_MFA_RECOMMENDATION_POLICY = 165_000_000
  MIN_DOWNLOADS_FOR_MFA_REQUIRED_POLICY = 180_000_000

  context "sending mail for mfa recommendation announcement" do
    setup do
      @user = create(:user)
      create(:rubygem, owners: [@user], downloads: MIN_DOWNLOADS_FOR_MFA_RECOMMENDATION_POLICY)

      Gemcutter::Application.load_tasks
      Rake::Task["mfa_policy:announce_recommendation"].invoke
      Delayed::Worker.new.work_off
    end

    should "send mail to users" do
      refute_empty ActionMailer::Base.deliveries
      email = ActionMailer::Base.deliveries.last
      assert_equal [@user.email], email.to
      assert_equal ["no-reply@mailer.rubygems.org"], email.from
      assert_equal "Please enable multi-factor authentication on your RubyGems account", email.subject
      assert_match "Thank you for making the RubyGems ecosystem more secure", email.text_part.body.to_s
    end
  end

  context "sending mail for mfa required soon announcement" do
    should "send mail to users with with more than 180M+ downloads and have MFA disabled" do
      @user = create(:user, mfa_level: "disabled")
      create(:rubygem, owners: [@user], downloads: MIN_DOWNLOADS_FOR_MFA_REQUIRED_POLICY)

      Gemcutter::Application.load_tasks
      Rake::Task["mfa_policy:reminder_enable_mfa"].invoke
      Delayed::Worker.new.work_off

      refute_empty ActionMailer::Base.deliveries
      email = ActionMailer::Base.deliveries.last
      assert_equal [@user.email], email.to
      assert_equal ["no-reply@mailer.rubygems.org"], email.from
      assert_equal "[Action Required] Enable multi-factor authentication on your RubyGems account by August 15", email.subject
      assert_match "Thank you for making the RubyGems ecosystem more secure", email.text_part.body.to_s
    end
  end

  teardown do
    Rake::Task["mfa_policy:announce_recommendation"].reenable
  end
end
