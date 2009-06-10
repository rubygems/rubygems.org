class RenameRequirementToName < ActiveRecord::Migration
  def self.up
    rename_column :dependencies, :requirement, :name
  end

  def self.down
    rename_column :dependencies, :name, :requirement
  end
end
