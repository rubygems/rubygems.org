# frozen_string_literal: true

class AddVersionHashAndDepsListToRedis < ActiveRecord::Migration[4.2]
  def self.up
    # NOOP because we removed redis
  end

  def self.down
    # NOOP because we removed redis
  end
end
