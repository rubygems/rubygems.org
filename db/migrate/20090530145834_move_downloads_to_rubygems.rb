class MoveDownloadsToRubygems < ActiveRecord::Migration
  def self.up
    remove_column :versions, :downloads
    add_column :rubygems, :downloads, :integer, default: 0
  end

  def self.down
    add_column :versions, :downloads, :integer, default: 0
    remove_column :rubygems, :downloads
  end
end
