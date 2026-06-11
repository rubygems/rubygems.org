# frozen_string_literal: true

# A small enabled/disabled status pill used by the MFA sections on the settings page.
class Settings::MfaStatusBadgeComponent < ApplicationComponent
  def initialize(enabled:)
    @enabled = enabled
    super()
  end

  def view_template
    span(class: "#{BASE} #{@enabled ? ENABLED : DISABLED}") do
      @enabled ? t("settings.edit.mfa.enabled") : t("settings.edit.mfa.disabled")
    end
  end

  BASE = "inline-flex items-center rounded-full px-3 py-0.5 text-b4 font-semibold"
  ENABLED = "bg-green-100 text-green-800 dark:bg-green-900/40 dark:text-green-200"
  DISABLED = "bg-neutral-200 text-neutral-700 dark:bg-neutral-800 dark:text-neutral-200"
end
