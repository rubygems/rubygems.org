class Avo::Resources::GemTypoException < Avo::BaseResource
  self.title = :name
  self.includes = []
  self.search = {
    query: lambda {
             query.where("name ILIKE ?", "%#{params[:q]}%")
           }
  }

  def fields
    field :id, as: :id, hide_on: :index

    field :name, as: :text, link_to_resource: true
    field :info, as: :textarea

    field :created_at, as: :date_time, sortable: true, readonly: true, only_on: %i[index show]
    field :updated_at, as: :date_time, sortable: true, readonly: true, only_on: %i[index show]
  end
end
