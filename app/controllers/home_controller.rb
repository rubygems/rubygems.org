# frozen_string_literal: true

class HomeController < ApplicationController
  def index
    @downloads_count = GemDownload.total_count
    respond_to do |format|
      format.html
    end
    expires_in 1.minute, public: true unless signed_in?
  end
end
