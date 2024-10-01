class Avo::Resources::Audit < Avo::BaseResource
  self.includes = %i[
    admin_github_user
    auditable
  ]

  def fields
    main_panel do
      field :action, as: :text

      if defined?(Avo::Pro)
        sidebar do
          panel_sidebar_contents
        end
      else
        panel_sidebar_contents
      end

      field :audited_changes, as: :audited_changes, except_on: :index
    end
  end

  def panel_sidebar_contents
    field :admin_github_user, as: :belongs_to
    field :created_at, as: :date_time
    field :comment, as: :text

    field :auditable, as: :belongs_to,
      polymorphic_as: :auditable,
      types: [::User, ::WebHook],
      name: "Edited Record"

    field :action_details, as: :heading

    field :audited_changes_arguments, as: :json_viewer, only_on: :show do |_model|
      record.audited_changes["arguments"]
    end
    field :audited_changes_fields, as: :json_viewer, only_on: :show do |_model|
      record.audited_changes["fields"]
    end
    field :audited_changes_models, as: :text, as_html: true, only_on: :show do
      record.audited_changes["models"]
    end

    field :id, as: :id
  end
end
