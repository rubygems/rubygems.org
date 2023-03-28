require "test_helper"

class ApplicationJobTest < ActiveSupport::TestCase
  test "good_job_concurrency_perform_limit" do
    callable = ApplicationJob.good_job_concurrency_perform_limit(default: 12)

    assert_equal 12, ApplicationJob.new.instance_exec(&callable)

    @launch_darkly.update(
      @launch_darkly.flag("good_job.concurrency.perform_limit")
      .variations(100, 5, 1)
      .variation_for_key("active_job", "ApplicationJob", 2)
    )

    assert_equal 1, ApplicationJob.new.instance_exec(&callable)
  end

  test "good_job_concurrency_enqueue_limit" do
    callable = ApplicationJob.good_job_concurrency_enqueue_limit(default: 12)

    assert_equal 12, ApplicationJob.new.instance_exec(&callable)

    @launch_darkly.update(
      @launch_darkly.flag("good_job.concurrency.enqueue_limit")
      .variations(100, 5, 1)
      .variation_for_key("active_job", "ApplicationJob", 2)
    )

    assert_equal 1, ApplicationJob.new.instance_exec(&callable)
  end
end
