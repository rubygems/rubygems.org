class AddVersionsCountToRubygems < ActiveRecord::Migration[4.2]
  def self.up
    add_column :rubygems, :versions_count, :integer, default: 0
  end

  def self.down
    remove_column :rubygems, :versions_count
  end
end
