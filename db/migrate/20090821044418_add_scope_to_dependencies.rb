class AddScopeToDependencies < ActiveRecord::Migration
  def self.up
    add_column :dependencies, :scope, :string
    Dependency.update_all(scope: 'runtime')
    announce "Please reprocess all gems after this migration"
  end

  def self.down
    remove_column :dependencies, :scope
  end
end
