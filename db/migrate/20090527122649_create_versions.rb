class CreateVersions < ActiveRecord::Migration
  def self.up
    create_table :versions do |table|
      table.string :authors
      table.text :description
      table.integer :downloads
      table.string :number
      table.integer :rubygem_id
      table.timestamps
    end

  end

  def self.down
    drop_table :versions
  end
end
