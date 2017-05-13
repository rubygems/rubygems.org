class RemoveVersionFromDependencies < ActiveRecord::Migration[4.2]
  def self.up
    remove_column :dependencies, :version_id
  end

  def self.down
    add_column :dependencies, :version_id, :integer
  end
end
