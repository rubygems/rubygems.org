# frozen_string_literal: true

class SponsorLogosController < ApplicationController
  include GitHubOAuthable

  def show
    blob = ActiveStorage::Blob.find_signed!(params[:signed_id])
    sponsor = Sponsor.joins(:logo_attachment).find_by!(active_storage_attachments: { blob_id: blob.id })
    return head :not_found unless Sponsor.in_footer.exists?(sponsor.id) || Admin::SponsorPolicy.new(admin_user, sponsor).download_logo?

    # No redirect to a reusable S3/Disk URL: every read checks visibility.
    # Never serve active content, even if a bad blob was inserted outside Avo.
    return head :not_found unless blob.content_type.in?(%w[image/png image/webp])

    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["Cache-Control"] = "private, no-store"
    send_data blob.download, type: blob.content_type, disposition: "inline"
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    head :not_found
  end
end
