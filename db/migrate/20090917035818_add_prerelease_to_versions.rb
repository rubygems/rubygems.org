class AddPrereleaseToVersions < ActiveRecord::Migration[4.2]
  def self.up
    add_column :versions, :prerelease, :boolean
    Version.update_all(prerelease: false)
  end

  def self.down
    remove_column :versions, :prerelease
  end
end
