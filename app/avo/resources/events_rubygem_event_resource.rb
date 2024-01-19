class EventsRubygemEventResource < Avo::BaseResource
  self.title = :cache_key
  self.includes = %i[rubygem ip_address]
  self.model_class = ::Events::RubygemEvent

  field :id, as: :id, hide_on: :index
  field :created_at, as: :date_time

  field :trace_id, as: :text, format_using: proc {
    if value.present?
      link_to(
        view == :index ? "🔗" : value,
        "https://app.datadoghq.com/logs?query=#{{
          :@traceid => value,
          from_ts: (model.created_at - 12.hours).to_i * 1000,
          to_ts: (model.created_at + 12.hours).to_i * 1000
        }.to_query}",
        { target: :_blank, rel: :noopener }
      )
    end
  }

  field :tag, as: :text
  field :rubygem, as: :belongs_to
  field :ip_address, as: :belongs_to
  field :additional, as: :event_additional, show_on: :index
end
