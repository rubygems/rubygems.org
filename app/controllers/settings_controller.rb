class SettingsController < ApplicationController
  before_action :redirect_to_signin, unless: :signed_in?
  before_action :redirect_to_new_mfa, if: :mfa_required_not_yet_enabled?
  before_action :set_cache_headers

  def edit
    @user = current_user
    @webauthn_credential = WebauthnCredential.new(user: @user)
    @mfa_options = [
      [t(".mfa.level.ui_and_api"), "ui_and_api"],
      [t(".mfa.level.ui_and_gem_signin"), "ui_and_gem_signin"],
      [t(".mfa.level.disabled"), "disabled"]
    ]
    @mfa_options.insert(2, [t(".mfa.level.ui_only"), "ui_only"]) if @user.mfa_ui_only?
  end
end
