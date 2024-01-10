class Avo::Resources::GemNameReservation < Avo::BaseResource
  self.title = :name
  self.includes = []
  if Gem.loaded_specs["avo-pro"]
    self.search_query = lambda {
      query.where("name LIKE ?", "%#{params[:q]}%")
    }
  end

  def fields
    field :id, as: :id
    field :name, as: :text
  end
end
