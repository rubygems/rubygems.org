class AuditResource < Avo::BaseResource
  self.title = :id
  self.includes = %i[
    admin_github_user
    auditable
  ]

  field :action, as: :text

  sidebar do
    field :admin_github_user, as: :belongs_to
    field :created_at, as: :date_time
    field :comment, as: :text

    field :auditable, as: :belongs_to,
      polymorphic_as: :auditable,
      types: [::User, ::WebHook],
      name: "Edited Record"

    heading "Action Details"

    field :audited_changes_arguments, as: :json_viewer, only_on: :show do |model|
      model.audited_changes["arguments"]
    end
    field :audited_changes_fields, as: :json_viewer, only_on: :show do |model|
      model.audited_changes["fields"]
    end
    field :audited_changes_models, as: :text, as_html: true, only_on: :show do
      model.audited_changes["models"]
    end

    field :id, as: :id
  end

  field :audited_changes, as: :audited_changes, except_on: :index
end
