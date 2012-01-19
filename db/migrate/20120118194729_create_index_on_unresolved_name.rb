class CreateIndexOnUnresolvedName < ActiveRecord::Migration
  def self.up
    add_index :dependencies, :unresolved_name
  end

  def self.down
    remove_index :dependencies, :unresolved_name
  end
end
