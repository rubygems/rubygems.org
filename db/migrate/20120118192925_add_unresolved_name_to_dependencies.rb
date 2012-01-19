class AddUnresolvedNameToDependencies < ActiveRecord::Migration
  def self.up
    add_column :dependencies, :unresolved_name, :string
  end

  def self.down
    remove_column :dependencies, :unresolved_name
  end
end
