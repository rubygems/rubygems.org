class GemNameReservationResource < Avo::BaseResource
  self.title = :name
  self.includes = []
  self.search_query = lambda {
    scope.where("name LIKE ?", "%#{params[:q]}%")
  }

  field :id, as: :id
  field :name, as: :text
end
