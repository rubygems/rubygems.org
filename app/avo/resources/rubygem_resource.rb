class RubygemResource < Avo::BaseResource
  self.title = :name
  self.includes = []
  self.search_query = lambda {
    scope.where("name LIKE ?", "%#{params[:q]}%")
  }

  action ReleaseReservedNamespace
  action AddOwner
  action YankRubygem
  action UploadInfoFile
  action UploadNamesFile
  action UploadVersionsFile

  class IndexedFilter < ScopeBooleanFilter; end
  filter IndexedFilter, arguments: { default: { with_versions: true, without_versions: true } }

  # Fields generated from the model
  field :name, as: :text, link_to_resource: true
  field :indexed, as: :boolean
  field :slug, as: :text, hide_on: :index
  field :id, as: :id, hide_on: :index
  field :protected_days, as: :number, hide_on: :index

  tabs style: :pills do
    field :versions, as: :has_many
    field :latest_version, as: :has_one

    field :ownerships, as: :has_many
    field :ownerships_including_unconfirmed, as: :has_many
    field :ownership_calls, as: :has_many
    field :ownership_requests, as: :has_many

    field :subscriptions, as: :has_many
    field :subscribers, as: :has_many, through: :subscriptions

    field :web_hooks, as: :has_many
    field :linkset, as: :has_one
    field :gem_download, as: :has_one

    field :link_verifications, as: :has_many
    field :oidc_rubygem_trusted_publishers, as: :has_many

    field :audits, as: :has_many
  end
end
