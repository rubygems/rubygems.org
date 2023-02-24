class WebHookResource < Avo::BaseResource
  self.title = :id
  self.includes = %i[user rubygem]

  action DeleteWebhook

  field :id, as: :id, link_to_resource: true

  field :url, as: :text
  field :failure_count, as: :number, sortable: true, index_text_align: :right
  field :user, as: :belongs_to
  field :rubygem, as: :belongs_to
  field :global?, as: :boolean

  tabs style: :pills do
    field :audits, as: :has_many
  end
end
