class NewsController < ApplicationController
  before_action :set_page

  def show
    @rubygems = Rubygem.news(7.days).page(@page).per(10).limit(100)
  end

  def popular
    @title = t(".title")
    @rubygems = Rubygem.by_downloads.news(70.days).page(@page).per(10).limit(100)

    render :show
  end
end
