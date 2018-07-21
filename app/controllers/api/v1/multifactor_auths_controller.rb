class Api::V1::MultifactorAuthsController < Api::BaseController
  before_action :authenticate_with_api_key
  before_action :verify_authenticated_user

  def show
    respond_to do |format|
      format.any(:all) { render plain: @api_user.mfa_level }
      format.json { render json: { mfa_level: @api_user.mfa_level } }
      format.yaml { render yaml: { mfa_level: @api_user.mfa_level } }
    end
  end
end
