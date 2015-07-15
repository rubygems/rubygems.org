class DropUnusedDatabaseColumns < ActiveRecord::Migration
  def self.up
    remove_column :ownerships, :approved
    remove_column :versions, :downloads_count
    drop_table :downloads
  end

  def self.down
    create_table "downloads" do |t|
      t.integer "version_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end
    add_column :versions, :downloads_count, :integer, default: 0
    add_column :ownerships, :approved, :boolean, default: false
  end
end
