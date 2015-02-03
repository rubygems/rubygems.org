class HomeController < ApplicationController
  def index
    @downloads_count = Download.count
  end
end
