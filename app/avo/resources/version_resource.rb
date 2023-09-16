class VersionResource < Avo::BaseResource
  self.title = :full_name
  self.includes = [:rubygem]
  self.search_query = lambda {
    scope.where("full_name LIKE ?", "#{params[:q]}%")
  }

  class IndexedFilter < ScopeBooleanFilter; end
  filter IndexedFilter, arguments: { default: { indexed: true, yanked: true } }

  field :full_name, as: :text, link_to_resource: true
  field :id, as: :id, hide_on: :index, as_html: true do |_id, *_args|
    link_to model.id, main_app.rubygem_version_url(model.rubygem.slug, model.slug)
  end

  field :rubygem, as: :belongs_to
  field :slug, as: :text, hide_on: :index
  field :number, as: :text
  field :platform, as: :text

  field :canonical_number, as: :text

  field :indexed, as: :boolean
  field :prerelease, as: :boolean
  field :position, as: :number
  field :latest, as: :boolean

  field :yanked_at, as: :date_time, sortable: true

  field :pusher, as: :belongs_to, class: "User"
  field :pusher_api_key, as: :belongs_to, class: "ApiKey"

  tabs do
    tab "Metadata", description: "Metadata that comes from the gemspec" do
      panel do
        field :summary, as: :textarea
        field :description, as: :textarea
        field :authors, as: :textarea
        field :licenses, as: :textarea
        field :cert_chain, as: :textarea
        field :built_at, as: :date_time, sortable: true
        field :metadata, as: :key_value, stacked: true
      end
    end

    tab "Runtime information" do
      panel do
        field :size, as: :number, sortable: true
        field :requirements, as: :textarea
        field :required_ruby_version, as: :text
        field :sha256, as: :text
        field :required_rubygems_version, as: :text
      end
    end

    tab "API" do
      panel do
        field :info_checksum, as: :text
        field :yanked_info_checksum, as: :text
      end
    end

    field :dependencies, as: :has_many
    field :gem_download, as: :has_one, name: "Downloads"
    field :deletion, as: :has_one
  end
end
