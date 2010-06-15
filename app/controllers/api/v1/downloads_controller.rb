class Api::V1::DownloadsController < ApplicationController
  def index
    render :json => {
      "total" => Download.count
    }
  end
end
