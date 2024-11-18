class Avo::Resources::Organization < Avo::BaseResource
  self.title = :name
  self.includes = []
  self.search = {
    query: lambda {
             query.where("name LIKE ? OR handle LIKE ?", "%#{params[:q]}%", "%#{params[:q]}%")
           }
  }

  self.find_record_method = lambda {
    query.find_by_handle!(id)
  }

  class DeletedFilter < Avo::Filters::ScopeBooleanFilter; end

  def filters
    filter DeletedFilter, arguments: { default: { not_deleted: true, deleted: false } }
  end

  def fields
    field :id, as: :id
    # Fields generated from the model
    field :handle, as: :text
    field :name, as: :text
    field :deleted_at, as: :date_time
    # add fields here
    tabs style: :pills do
      field :memberships, as: :has_many
      field :unconfirmed_memberships, as: :has_many
      field :users, as: :has_many
      field :rubygems, as: :has_many
      field :organization_onboarding, as: :belongs_to
    end
  end
end
