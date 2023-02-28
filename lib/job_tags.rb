module JobTags
  extend ActiveSupport::Concern

  included do
    def statsd_tags
      { queue: queue_name, priority: priority, job_class: self.class.name }
    end
  end
end
