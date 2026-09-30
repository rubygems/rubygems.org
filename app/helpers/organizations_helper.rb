# frozen_string_literal: true

module OrganizationsHelper
  # Relative time until the invitation expires (e.g. "7 days"), with the exact UTC time as a tooltip.
  def invitation_expiry_tag(membership)
    expires_at = membership.invitation_expires_at
    time_tag(
      expires_at,
      distance_of_time_in_words_to_now(expires_at),
      title: t("organizations.invitation_expiry_title", time: l(expires_at.utc, format: :long)),
      class: "cursor-help"
    )
  end
end
