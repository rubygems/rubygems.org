class AddMissingIndicies < ActiveRecord::Migration[4.2]
  def self.up
    add_index 'rubygems', 'name'
    add_index 'linksets', 'rubygem_id'
    add_index 'versions', 'rubygem_id'
    add_index 'requirements', 'version_id'
    add_index 'requirements', 'dependency_id'
    add_index 'dependencies', 'rubygem_id'
  end

  def self.down
    remove_index 'rubygems', 'name'
    remove_index 'linksets', 'rubygem_id'
    remove_index 'versions', 'rubygem_id'
    remove_index 'requirements', 'version_id'
    remove_index 'requirements', 'dependency_id'
    remove_index 'dependencies', 'rubygem_id'
  end
end
