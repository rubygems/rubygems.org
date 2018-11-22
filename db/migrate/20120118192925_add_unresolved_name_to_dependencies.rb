class AddUnresolvedNameToDependencies < ActiveRecord::Migration[4.2]
  def self.up
    add_column :dependencies, :unresolved_name, :string
  end

  def self.down
    remove_column :dependencies, :unresolved_name
  end
end
