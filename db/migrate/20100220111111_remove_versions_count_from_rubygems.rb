class RemoveVersionsCountFromRubygems < ActiveRecord::Migration
  def self.up
    remove_column :rubygems, :versions_count
  end

  def self.down
    add_column :rubygems, :versions_count, :integer, default: 0
  end
end
