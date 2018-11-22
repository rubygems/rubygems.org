class AddMoreIndexesToVersions < ActiveRecord::Migration[4.2]
  def self.up
    add_index :versions, :number
    add_index :versions, :built_at
    add_index :versions, :created_at
  end

  def self.down
    remove_index :versions, :number
    remove_index :versions, :built_at
    remove_index :versions, :created_at
  end
end
