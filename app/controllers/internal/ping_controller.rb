class Internal::PingController < ApplicationController
  def index
    render plain: 'PONG'
  end

  def revision
    render plain: AppRevision.version
  end
end
