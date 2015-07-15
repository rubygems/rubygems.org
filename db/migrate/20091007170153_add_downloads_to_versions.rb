class AddDownloadsToVersions < ActiveRecord::Migration
  def self.up
    add_column :versions, :downloads_count, :integer, default: 0
  end

  def self.down
    remove_column :versions, :downloads_count
  end
end
