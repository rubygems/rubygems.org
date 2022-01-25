class Api::V1::ProfilesController < Api::BaseController
  before_action :set_user, only: [:show]

  def show
    respond_to do |format|
      format.json { render json: @user, sensitive_fields: @show_sensitive_fields }
      format.yaml { render yaml: @user, sensitive_fields: @show_sensitive_fields }
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
      @show_sensitive_fields = true
    end
  end
end
