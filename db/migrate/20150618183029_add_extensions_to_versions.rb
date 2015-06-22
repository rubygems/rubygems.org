class AddExtensionsToVersions < ActiveRecord::Migration
  def change
    add_column :versions, :extensions, :boolean
  end
end
