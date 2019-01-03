# frozen_string_literal: true

class Internal::PingController < ApplicationController
  def index
    ActiveRecord::Base.connection.select_value('SELECT 1') == 1 or \
      raise StandardError, 'Failed to SELECT 1 from DB server'
    render plain: 'PONG'
  end

  def revision
    render plain: AppRevision.version
  end
end
