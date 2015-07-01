class HomeController < ApplicationController
  def index
    @downloads_count = Download.count
    respond_to do |format|
      format.html
    end
  end
end
