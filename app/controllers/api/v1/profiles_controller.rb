class Api::V1::ProfilesController < Api::BaseController
  def show
    @user = User.find_by_slug!(params[:id])
    render_as @user
  end
end
