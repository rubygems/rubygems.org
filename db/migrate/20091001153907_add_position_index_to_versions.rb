class AddPositionIndexToVersions < ActiveRecord::Migration[4.2]
  def self.up
    add_index :versions, :position
  end

  def self.down
    remove_index :versions, :position
  end
end
