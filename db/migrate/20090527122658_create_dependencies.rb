class CreateDependencies < ActiveRecord::Migration
  def self.up
    create_table :dependencies do |table|
      table.string :name
      table.integer :rubygem_id
      table.string :requirement
      table.timestamps
    end
  end

  def self.down
    drop_table :dependencies
  end
end
