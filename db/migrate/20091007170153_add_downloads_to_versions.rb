class AddDownloadsToVersions < ActiveRecord::Migration[4.2]
  def self.up
    add_column :versions, :downloads_count, :integer, default: 0
  end

  def self.down
    remove_column :versions, :downloads_count
  end
end
