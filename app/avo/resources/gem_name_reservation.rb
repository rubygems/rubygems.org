class Avo::Resources::GemNameReservation < Avo::BaseResource
  self.title = :name
  self.includes = []
  self.search = {
    query: lambda {
             query.where("name LIKE ?", "%#{params[:q]}%")
           }
  }

  def fields
    field :id, as: :id
    field :name, as: :text
  end
end
