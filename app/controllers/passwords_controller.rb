# frozen_string_literal: true

class PasswordsController < Clearance::PasswordsController
  before_action :validate_confirmation_token, only: :edit

  def find_user_for_create
    Clearance.configuration.user_model
      .find_by_normalized_email password_params[:email]
  end

  private

  def url_after_update
    dashboard_path
  end

  def password_params
    params.require(:password).permit(:email)
  end

  def validate_confirmation_token
    user = find_user_for_edit
    return if user&.valid_confirmation_token?
    redirect_to root_path, alert: t('failure_when_forbidden')
  end
end
