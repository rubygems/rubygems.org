require "test_helper"

class OwnershipRequestMailerTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  context "sending mail for ownership request" do
    setup do
      @ownership = create(:ownership)
      create(:ownership_request, rubygem: @ownership.rubygem, created_at: 1.hour.ago)
      Rake::Task["ownership_request_notification:send"].invoke
      perform_enqueued_jobs only: ActionMailer::MailDeliveryJob
    end

    should "send mail to owners" do
      refute_empty ActionMailer::Base.deliveries
      email = ActionMailer::Base.deliveries.last

      assert_equal [@ownership.user.email], email.to
      assert_equal ["no-reply@mailer.rubygems.org"], email.from
      assert_equal "New ownership request(s) for #{@ownership.rubygem.name}", email.subject
      assert_match "<em>1</em> new ownership requests", email.body.to_s
    end
  end

  teardown do
    Rake::Task["ownership_request_notification:send"].reenable
  end
end
