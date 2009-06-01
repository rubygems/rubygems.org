class MoveDependenciesToVersions < ActiveRecord::Migration
  def self.up
    remove_column :dependencies, :rubygem_id
    add_column :dependencies, :version_id, :integer
  end

  def self.down
    remove_column :dependencies, :version_id
    add_column :dependencies, :rubygem_id, :integer
  end
end
