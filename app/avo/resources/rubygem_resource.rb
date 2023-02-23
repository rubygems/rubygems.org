class RubygemResource < Avo::BaseResource
  self.title = :name
  self.includes = []
  self.search_query = lambda {
    scope.where("name LIKE ?", "%#{params[:q]}%")
  }

  action ReleaseReservedNamespace

  # Fields generated from the model
  field :name, as: :text, link_to_resource: true
  field :indexed, as: :boolean
  field :slug, as: :text, hide_on: :index
  field :id, as: :id, hide_on: :index
  field :protected_days, as: :text

  heading "Versions"

  # field :latest_version, as: :has_one
  # field :versions, as: :has_many

  heading "Owners"

  # field :ownerships, as: :has_many
  # field :ownerships_including_unconfirmed, as: :has_many
  # field :owners, as: :has_many, through: :ownerships
  # field :owners_including_unconfirmed, as: :has_many, through: :ownerships_including_unconfirmed
  # field :push_notifiable_owners, as: :has_many, through: :ownerships
  # field :ownership_notifiable_owners, as: :has_many, through: :ownerships
  # field :ownership_request_notifiable_owners, as: :has_many, through: :ownerships
  # field :ownership_calls, as: :has_many
  # field :ownership_requests, as: :has_many

  heading "Subscriptions"

  # field :subscriptions, as: :has_many
  # field :subscribers, as: :has_many, through: :subscriptions

  heading "Metadata"

  # field :web_hooks, as: :has_many
  # field :linkset, as: :has_one
  # field :gem_download, as: :has_one

  heading "Audits"

  # field :audits, as: :has_many
end
