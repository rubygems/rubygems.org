class AddExtensionsToVersions < ActiveRecord::Migration
  def change
    add_column :versions, :extensions, :boolean, default: false
  end
end
