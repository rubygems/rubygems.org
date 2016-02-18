module Gemcutter
  # Feature flag for counting downloads through stats-update or FastlyLogProcessor
  ENABLE_FASTLY_LOG_PROCESSOR = Rails.env.test? || Rails.env.development?
end
