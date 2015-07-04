class AddPrereleaseToVersions < ActiveRecord::Migration
  def self.up
    add_column :versions, :prerelease, :boolean
    Version.update_all(prerelease: false)
  end

  def self.down
    remove_column :versions, :prerelease
  end
end
