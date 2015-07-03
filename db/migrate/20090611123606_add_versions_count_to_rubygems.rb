class AddVersionsCountToRubygems < ActiveRecord::Migration
  def self.up
    add_column :rubygems, :versions_count, :integer, default: 0
  end

  def self.down
    remove_column :rubygems, :versions_count
  end
end
