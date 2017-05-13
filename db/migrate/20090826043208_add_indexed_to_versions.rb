class AddIndexedToVersions < ActiveRecord::Migration[4.2]
  def self.up
    add_column :versions, :indexed, :boolean, default: true
  end

  def self.down
    remove_column :versions, :indexed
  end
end
