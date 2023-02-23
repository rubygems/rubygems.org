module TraceTagger
  extend ActiveSupport::Concern

  included do
    delegate :set_tag, :set_tags, to: "Datadog::Tracing.active_span", allow_nil: true

    def trace(...)
      return yield unless Datadog::Tracing.enabled?

      Datadog::Tracing.trace(...)
    end
  end
end
