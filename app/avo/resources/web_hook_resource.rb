class WebHookResource < Avo::BaseResource
  self.title = :id
  self.includes = %i[user rubygem]

  action DeleteWebhook
  class EnabledFilter < ScopeBooleanFilter; end
  filter EnabledFilter, arguments: { default: { enabled: true, disabled: false } }
  class GlobalFilter < ScopeBooleanFilter; end
  filter GlobalFilter, arguments: { default: { global: true, specific: true } }

  field :id, as: :id, link_to_resource: true

  field :url, as: :text
  field :enabled?, as: :boolean
  field :failure_count, as: :number, sortable: true, index_text_align: :right
  field :user, as: :belongs_to
  field :rubygem, as: :belongs_to
  field :global?, as: :boolean

  field :hook_relay_stream, as: :text do
    stream_name = "webhook_id-#{model.id}"
    link_to stream_name, "https://app.hookrelay.dev/hooks/#{ENV['HOOK_RELAY_STREAM_ID']}?started_at=P1W&stream=#{stream_name}"
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
