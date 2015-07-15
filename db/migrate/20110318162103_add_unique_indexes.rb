class AddUniqueIndexes < ActiveRecord::Migration
  def self.up
    remove_index :rubygems, column: [:name]
    add_index :rubygems, [:name], unique: true
    add_index :versions, [:rubygem_id, :number, :platform], unique: true
  end

  def self.down
    remove_index :versions, column: [:rubygem_id, :number, :platform]
    remove_index :rubygems, column: [:name]
    add_index :rubygems, [:name]
  end
end
