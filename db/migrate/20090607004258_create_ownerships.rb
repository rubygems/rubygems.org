class CreateOwnerships < ActiveRecord::Migration
  def self.up
    create_table :ownerships do |table|
      table.belongs_to :rubygem
      table.belongs_to :user
      table.string :token
      table.boolean :approved, default: false
      table.timestamps
    end

    add_index :ownerships, :rubygem_id
    add_index :ownerships, :user_id
  end

  def self.down
    remove_index :ownerships, :rubygem_id
    remove_index :ownerships, :user_id
    drop_table :ownerships
  end
end
