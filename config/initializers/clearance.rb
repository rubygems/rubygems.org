require 'clearance/confirmations_controller'
require 'clearance/passwords_controller'
require 'clearance/sessions_controller'
require 'clearance/users_controller'

class Clearance::SessionsController
  private
  def url_after_create
    dashboard_url
  end
end
