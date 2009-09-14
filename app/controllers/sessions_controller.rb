class SessionsController < Clearance::SessionsController
  private
  def url_after_create
    dashboard_url
  end
end
