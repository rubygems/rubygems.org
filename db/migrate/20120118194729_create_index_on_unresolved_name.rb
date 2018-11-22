class CreateIndexOnUnresolvedName < ActiveRecord::Migration[4.2]
  def self.up
    add_index :dependencies, :unresolved_name
  end

  def self.down
    remove_index :dependencies, :unresolved_name
  end
end
