class AddPositionIndexToVersions < ActiveRecord::Migration
  def self.up
    add_index :versions, :position
  end

  def self.down
    remove_index :versions, :position
  end
end
