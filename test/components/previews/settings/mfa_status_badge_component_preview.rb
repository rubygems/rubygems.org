# frozen_string_literal: true

class Settings::MfaStatusBadgeComponentPreview < Lookbook::Preview
  layout "hammy_component_preview"

  # @param enabled toggle "enabled"
  def default(enabled: true)
    render Settings::MfaStatusBadgeComponent.new(enabled: enabled)
  end
end
