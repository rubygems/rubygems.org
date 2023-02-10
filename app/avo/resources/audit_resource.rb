class AuditResource < Avo::BaseResource
  self.title = :id
  self.includes = %i[
    admin_github_user
    auditable
  ]
  # self.search_query = -> do
  #   scope.ransack(id_eq: params[:q], m: "or").result(distinct: false)
  # end

  field :action, as: :text
  field :auditable, as: :belongs_to,
    polymorphic_as: :auditable,
    types: [::User]
  field :admin_github_user, as: :belongs_to
  field :created_at, as: :date_time
  field :comment, as: :text
  # Fields generated from the model
  field :audited_changes_arguments, as: :json_viewer, only_on: :show do |model|
    model.audited_changes["arguments"]
  end
  field :audited_changes_fields, as: :json_viewer, only_on: :show do |model|
    model.audited_changes["fields"]
  end
  field :audited_changes_model, as: :text, only_on: :show do |model|
    model.audited_changes["model"]
  end
  field :audited_changes, as: :audited_changes
  field :id, as: :id
  # add fields here
end
