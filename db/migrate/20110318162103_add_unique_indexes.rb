class AddUniqueIndexes < ActiveRecord::Migration
  def self.up
    remove_index :versions, :rubygem_id
    remove_index :versions, :number
    remove_index :rubygems, :name
    add_index :rubygems, [:name], :unique => true
    add_index :versions, [:rubygem_id, :number, :platform], :unique => true
  end

  def self.down
    remove_index :versions, :column => [:rubygem_id, :number, :platform]
    remove_index :rubygems, :column => [:name]
    add_index :rubygems, :name
    add_index :versions, :number
    add_index :versions, :rubygem_id
  end
end
