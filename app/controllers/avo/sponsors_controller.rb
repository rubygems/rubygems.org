# frozen_string_literal: true

class Avo::SponsorsController < Avo::ResourcesController
  # Community Avo skips its policy service. Keep this security gate effective
  # even when the optional paid edition is absent in development/test.
  prepend_before_action :authorize_sponsor_admin
  before_action :require_multipart_logo, only: %i[create update]

  private

  def authorize_sponsor_admin
    raise Avo::NotAuthorizedError unless Admin::SponsorPolicy.new(admin_user, Sponsor).avo_index?
  end

  def require_multipart_logo
    logo = params.dig(:sponsor, :logo)
    return if logo.blank? || logo.is_a?(ActionDispatch::Http::UploadedFile)

    # Avo's failed new-record preview deletes the supplied blob. Never let a
    # signed ID for an existing attachment reach that renderer.
    head :unprocessable_content
  end
end
