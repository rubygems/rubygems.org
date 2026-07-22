# frozen_string_literal: true

require "test_helper"

class CacheExposureMailDeliveryJobTest < ActiveJob::TestCase
  should "be the delivery job CacheExposureMailer uses" do
    assert_equal CacheExposureMailDeliveryJob, CacheExposureMailer.delivery_job
  end

  should "subclass the standard mail delivery job so queue routing and rendering are unchanged" do
    assert_operator CacheExposureMailDeliveryJob, :<, ActionMailer::MailDeliveryJob
  end

  should "cap concurrent sends to protect the DB during the bulk run" do
    config = CacheExposureMailDeliveryJob.good_job_concurrency_config

    assert_equal 5, config[:perform_limit]
    # No enqueue_limit: every notice must still be enqueued; only concurrent delivery is capped.
    assert_nil config[:enqueue_limit]
  end

  should "share one fleet-wide concurrency key across both notices" do
    key = CacheExposureMailDeliveryJob.new.good_job_concurrency_key

    assert_equal "CacheExposureMailDeliveryJob", key
  end
end
