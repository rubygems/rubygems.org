class RemoveVersionFromDependencies < ActiveRecord::Migration
  def self.up
    remove_column :dependencies, :version_id
  end

  def self.down
    add_column :dependencies, :version_id, :integer
  end
end
