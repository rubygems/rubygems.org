class HomeController < ApplicationController
  def index
    @downloads_count = GemDownload.total_count
    respond_to do |format|
      format.html
    end
  end

  def nav_profile_links
    respond_to do |format|
      format.html
      render template: "layouts/_nav_profile_links", layout: false
    end
  end

  def mobile_nav_profile_links
    respond_to do |format|
      format.html
      render template: "layouts/_mobile_nav_profile_links", layout: false
    end
  end
end
