class AddPusherToVersions < ActiveRecord::Migration[5.2]
  def change
    add_belongs_to :versions, :pusher, foreign_key: false
  end
end
