# frozen_string_literal: true

class HomeController < ApplicationController
  def index
    @downloads_count = GemDownload.total_count
    respond_to do |format|
      format.html
    end
    set_surrogate_key "homepage"
    cache_expiry_headers(expiry: 60.seconds, fastly_expiry: 60.seconds) if cacheable_request?
  end
end
