# frozen_string_literal: true

class Api::V1::Versions::DownloadsController < Api::BaseController
  def index
    render plain: "This endpoint is not supported anymore", status: :gone
  end

  def search
    render plain: "This endpoint is not supported anymore", status: :gone
  end
end
