class Api::V1::ProfilesController < Api::BaseController
  before_action :set_user, only: [:show]

  def show
    respond_to do |format|
      format.json { render json: @user }
      format.yaml { render yaml: @user }
    end
  end

  private

  def set_user
    if params[:id]
      @user = User.find_by_slug!(params[:id])
    else
      authenticate_or_request_with_http_basic do |username, password|
        @user = User.authenticate(username.strip, password)
      end
      @user&.hide_mfa = false
    end
  end
end
