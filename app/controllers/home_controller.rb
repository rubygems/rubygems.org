class HomeController < ApplicationController
  def index
    begin
      @downloads_count = Download.count
    rescue Redis::CannotConnectError
    end
    respond_to do |format|
      format.html
    end
  end
end
