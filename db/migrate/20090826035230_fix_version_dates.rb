class FixVersionDates < ActiveRecord::Migration[4.2]
  def self.up
    rename_column :versions, :created_at, :built_at
    add_column :versions, :created_at, :datetime
    Version.update_all('created_at = updated_at')
  end

  def self.down
    remove_column :versions, :created_at
    rename_column :versions, :built_at, :created_at
  end
end
