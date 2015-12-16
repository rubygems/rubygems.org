class Internal::PingController < ApplicationController
  def index
    ActiveRecord::Base.connection.select_value('SELECT 1') == '1' or \
      fail StandardError, 'Failed to SELECT 1 from DB server'
    Redis.current.set('PING', 1) or \
      fail StandardError, 'Failed to write PING=1 to redis'
    render text: 'PONG'
  end

  def revision
    render text: AppRevision.version
  end
end
