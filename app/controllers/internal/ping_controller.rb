class Internal::PingController < ApplicationController
  def index
    ActiveRecord::Base.connection.select_value('SELECT 1') == '1' or \
      raise StandardError, 'Failed to SELECT 1 from DB server'
    render text: 'PONG'
  end

  def revision
    render text: AppRevision.version
  end
end
