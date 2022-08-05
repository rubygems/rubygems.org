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
      assert_match "Recently, we've announced our security-focused ambitions to the community.", email.text_part.body.to_s
    end
  end

  context "sending mail for mfa required soon announcement" do
    should "send mail to users with with more than 180M+ downloads and have MFA disabled" do
      ActionMailer::Base.deliveries.clear
      
      @user = create(:user, mfa_level: "disabled")
      create(:rubygem, owners: [@user], downloads: MIN_DOWNLOADS_FOR_MFA_REQUIRED_POLICY)

      Gemcutter::Application.load_tasks
      Rake::Task["mfa_policy:reminder_enable_mfa"].invoke
      Delayed::Worker.new.work_off

      sleep 4

      refute_empty ActionMailer::Base.deliveries
      email = ActionMailer::Base.deliveries.last
      assert_equal [@user.email], email.to
      assert_equal ["no-reply@mailer.rubygems.org"], email.from
      assert_equal "[Action Required] Enable multi-factor authentication on your RubyGems account by August 15", email.subject
      assert_match "Recently, we've announced our security-focused ambitions to the community.", email.text_part.body.to_s
    end

    should "send mail to users with with more than 180M+ downloads and have weak MFA" do
      ActionMailer::Base.deliveries.clear
     
      user = create(:user, mfa_level: "ui_only")
      create(:rubygem, owners: [user], downloads: MIN_DOWNLOADS_FOR_MFA_REQUIRED_POLICY)

      Gemcutter::Application.load_tasks
      Rake::Task["mfa_policy:reminder_enable_mfa"].invoke
      Delayed::Worker.new.work_off

      sleep 4

      refute_empty ActionMailer::Base.deliveries
      email = ActionMailer::Base.deliveries.last
      assert_equal [user.email], email.to
      assert_equal ["no-reply@mailer.rubygems.org"], email.from
      assert_equal "[Action Required] Enable multi-factor authentication on your RubyGems account by August 15", email.subject
      assert_match "Recently, we've announced our security-focused ambitions to the community.", email.text_part.body.to_s
    end

    should "not send mail to users with with more than 180M+ downloads and have strong MFA" do
      ActionMailer::Base.deliveries.clear

      user = create(:user, mfa_level: "ui_and_api")
      create(:rubygem, owners: [user], downloads: MIN_DOWNLOADS_FOR_MFA_REQUIRED_POLICY)

      Gemcutter::Application.load_tasks
      Rake::Task["mfa_policy:reminder_enable_mfa"].invoke
      Delayed::Worker.new.work_off

      sleep 4

      assert_empty ActionMailer::Base.deliveries
    end

    should "not send mail to users with with less than 180M downloads" do
      ActionMailer::Base.deliveries.clear
      user = create(:user)
      create(:rubygem, owners: [user], downloads: MIN_DOWNLOADS_FOR_MFA_REQUIRED_POLICY - 1)

      Gemcutter::Application.load_tasks
      Rake::Task["mfa_policy:reminder_enable_mfa"].invoke
      Delayed::Worker.new.work_off

      sleep 4

      assert_empty ActionMailer::Base.deliveries
    end
  end

  teardown do
    Rake::Task["mfa_policy:announce_recommendation"].reenable
  end
end
