# frozen_string_literal: true

class Api::V1::ProfilesController < Api::BaseController
  def show
    @user = User.find_by_slug!(params[:id])
    respond_to do |format|
      format.json { render json: @user }
      format.yaml { render yaml: @user }
    end
  end
end
