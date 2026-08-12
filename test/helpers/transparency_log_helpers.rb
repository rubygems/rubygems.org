# frozen_string_literal: true

module TransparencyLogHelpers
  extend ActiveSupport::Concern

  TEST_BASELINE_ID = "018f8f5b-c6d4-7e36-8d74-6a0ea99850f1"
  TEST_BASELINE_OBSERVED_AT = Time.zone.parse("2026-08-12T01:02:03Z")
  TEST_PRIVATE_KEY = OpenSSL::PKey::EC.generate("prime256v1")
  TEST_REKOR_URL = "http://localhost:3004"

  included do
    setup :configure_transparency_log_test_environment
  end

  def build_transparency_log_baseline_task(task_class, **attributes)
    task_class.new.tap do |task|
      task.assign_attributes(transparency_log_baseline_attributes.merge(attributes))
    end
  end

  def transparency_log_baseline_attributes
    {
      baseline_id: TEST_BASELINE_ID,
      observed_at: TEST_BASELINE_OBSERVED_AT
    }
  end

  private

  def configure_transparency_log_test_environment
    TransparencyLog.configuration.private_key ||= TEST_PRIVATE_KEY.to_pem
    TransparencyLog.configuration.rekor_url ||= TEST_REKOR_URL
  end
end
