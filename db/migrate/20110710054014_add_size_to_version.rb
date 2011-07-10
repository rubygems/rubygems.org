class AddSizeToVersion < ActiveRecord::Migration
  def self.up
    add_column :versions, :size, :integer
  end

  def self.down
    remove_column :versions, :size
  end
end
