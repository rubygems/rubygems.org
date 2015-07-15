class AddIndexedToVersions < ActiveRecord::Migration
  def self.up
    add_column :versions, :indexed, :boolean, default: true
  end

  def self.down
    remove_column :versions, :indexed
  end
end
