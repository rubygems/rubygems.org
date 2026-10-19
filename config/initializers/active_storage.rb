# frozen_string_literal: true

# Small sponsor logos use authenticated multipart Avo forms. Do not expose
# storage write credentials through Rails' or Avo's direct upload endpoints.
module RestrictActiveStorageRoutes
  def create
    head :not_found
  end

  def destroy
    return head :not_found if params[:resource_name] == "sponsors"

    super
  end
end

Rails.application.config.to_prepare do
  ActiveStorage::DirectUploadsController.prepend RestrictActiveStorageRoutes

  # Avo's attachment API uploads before saving, bypassing the audited form.
  # Multipart create/update forms remain the only sponsor upload path.
  Avo::AttachmentsController.prepend RestrictActiveStorageRoutes
end
