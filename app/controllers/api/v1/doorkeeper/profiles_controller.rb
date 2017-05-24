class Api::V1::Doorkeeper::ProfilesController < Api::BaseController
  before_action :doorkeeper_authorize!

  def show
    profile_info = current_user.as_json
    profile_info['email'] = current_user.email unless profile_info['email']

    render json: profile_info
  end
end
