class Avo::Resources::WebHook < Avo::BaseResource
  self.includes = %i[user rubygem]

  def actions
    action Avo::Actions::DeleteWebhook
  end

  class EnabledFilter < Avo::Filters::ScopeBooleanFilter; end
  class GlobalFilter < Avo::Filters::ScopeBooleanFilter; end

  def filters
    filter EnabledFilter, arguments: { default: { enabled: true, disabled: false } }
    filter GlobalFilter, arguments: { default: { global: true, specific: true } }
  end

  def fields
    field :id, as: :id, link_to_resource: true

    field :url, as: :text
    field :enabled?, as: :boolean
    field :failure_count, as: :number, sortable: true, html: { index: { wrapper: { classes: "text-right" } } }
    field :user, as: :belongs_to
    field :rubygem, as: :belongs_to
    field :global?, as: :boolean

    field :hook_relay_stream, as: :text do
      stream_name = "webhook_id-#{record.id}"
      link_to stream_name, "https://app.hookrelay.dev/hooks/#{ENV['HOOK_RELAY_HOOK_ID']}?started_at=P1W&stream=#{stream_name}"
    end

    field :disabled_reason, as: :text
    field :disabled_at, as: :date_time, sortable: true
    field :last_success, as: :date_time, sortable: true
    field :last_failure, as: :date_time, sortable: true
    field :successes_since_last_failure, as: :number, sortable: true
    field :failures_since_last_success, as: :number, sortable: true

    tabs style: :pills do
      field :audits, as: :has_many
    end
  end
end
