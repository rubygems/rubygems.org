class LinkVerificationResource < Avo::BaseResource
  self.title = :id
  self.includes = []
  # self.search_query = -> do
  #   scope.ransack(id_eq: params[:q], m: "or").result(distinct: false)
  # end

  field :id, as: :id
  # Fields generated from the model
  field :linkable, as: :belongs_to,
    polymorphic_as: :linkable,
    types: %w[Rubygem]
  field :uri, as: :text
  field :verified?, as: :boolean
  field :last_verified_at, as: :date_time
  field :last_failure_at, as: :date_time
  field :failures_since_last_verification, as: :number
  # add fields here
end
