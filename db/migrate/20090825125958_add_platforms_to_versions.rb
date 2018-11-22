class AddPlatformsToVersions < ActiveRecord::Migration[4.2]
  def self.up
    add_column :versions, :platform, :string
  end

  def self.down
    remove_column :versions, :platform
  end
end
