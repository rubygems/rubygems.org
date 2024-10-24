class Avo::Resources::AttestationResource < Avo::BaseResource
  self.title = :id
  self.includes = []

  def fields
    field :id, as: :id
    # Fields generated from the model
    field :version, as: :belongs_to
    field :body, as: :json_viewer
    field :media_type, as: :text
    # add fields here
  end
end
