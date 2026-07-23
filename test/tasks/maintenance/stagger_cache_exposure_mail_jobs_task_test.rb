# frozen_string_literal: true

require "test_helper"

class Maintenance::StaggerCacheExposureMailJobsTaskTest < ActiveSupport::TestCase
  include ActiveSupport::Testing::TimeHelpers

  setup do
    @task = Maintenance::StaggerCacheExposureMailJobsTask.new
  end

  def create_good_job(job_class: "CacheExposureMailDeliveryJob", queue_name: "within_24_hours",
    scheduled_at: 1.hour.ago, finished_at: nil)
    GoodJob::Job.create!(
      id: SecureRandom.uuid,
      active_job_id: SecureRandom.uuid,
      job_class: job_class,
      queue_name: queue_name,
      scheduled_at: scheduled_at,
      finished_at: finished_at,
      serialized_params: { "job_class" => job_class, "queue_name" => queue_name }
    )
  end

  context "#collection" do
    should "cover only queued cache-exposure mail jobs" do
      queued = create_good_job
      other_class = create_good_job(job_class: "ActionMailer::MailDeliveryJob")
      other_queue = create_good_job(queue_name: "mailers")
      finished = create_good_job(finished_at: Time.current)

      covered = @task.collection.each_record.to_a

      assert_includes covered, queued
      refute_includes covered, other_class
      refute_includes covered, other_queue
      refute_includes covered, finished
    end
  end

  context "#process" do
    should "schedule successive batches one wave interval apart, starting in the future" do
      freeze_time do
        jobs = Array.new(4) { create_good_job }
        @task.batch_size = 2

        @task.collection.each { |batch| @task.process(batch) }

        waves = jobs.map { |job| job.reload.scheduled_at }.uniq.sort

        assert_equal [3.minutes.from_now, 6.minutes.from_now], waves
        waves.each { |wave| assert_operator wave, :>, Time.current }
      end
    end

    should "not reschedule jobs outside the collection" do
      untouched = create_good_job(job_class: "ActionMailer::MailDeliveryJob", scheduled_at: 2.hours.ago)
      create_good_job

      @task.collection.each { |batch| @task.process(batch) }

      assert_equal 2.hours.ago.to_i, untouched.reload.scheduled_at.to_i
    end

    should "continue after the latest scheduled wave when resumed" do
      freeze_time do
        create_good_job(scheduled_at: 30.minutes.from_now)
        resumed = create_good_job

        # GoodJob::Job's primary key is active_job_id, so #id returns that UUID.
        @task.process(GoodJob::Job.where(active_job_id: resumed.id))

        assert_equal 33.minutes.from_now, resumed.reload.scheduled_at
      end
    end

    should "respect a custom wave interval" do
      freeze_time do
        job = create_good_job
        @task.wave_interval_minutes = 10

        @task.collection.each { |batch| @task.process(batch) }

        assert_equal 10.minutes.from_now, job.reload.scheduled_at
      end
    end
  end

  context "validations" do
    should "reject non-positive batch size and wave interval" do
      @task.batch_size = 0

      refute_predicate @task, :valid?

      @task.batch_size = 1000
      @task.wave_interval_minutes = -1

      refute_predicate @task, :valid?
    end
  end
end
