# frozen_string_literal: true

class Maintenance::StaggerCacheExposureMailJobsTask < MaintenanceTasks::Task
  include SemanticLogger::Loggable

  JOB_CLASS = "CacheExposureMailDeliveryJob"
  QUEUE_NAME = "within_24_hours"

  attribute :batch_size, :integer, default: 1000
  attribute :wave_interval_minutes, :integer, default: 3
  validates :batch_size, numericality: { only_integer: true, greater_than: 0 }
  validates :wave_interval_minutes, numericality: { only_integer: true, greater_than: 0 }

  def collection
    queued_jobs.in_batches(of: batch_size)
  end

  def process(batch)
    wave_at = next_wave_at
    staggered = batch.update_all(scheduled_at: wave_at)
    logger.info("Staggered cache-exposure mail wave", scheduled_at: wave_at, jobs: staggered)
  end

  private

  def queued_jobs
    GoodJob::Job.where(job_class: JOB_CLASS, queue_name: QUEUE_NAME, finished_at: nil)
  end

  def next_wave_at
    latest = queued_jobs.maximum(:scheduled_at)
    [latest, Time.current].compact.max + wave_interval_minutes.minutes
  end
end
