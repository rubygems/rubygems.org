class RemoveUserIdFromRubygems < ActiveRecord::Migration
  def self.up
    remove_column :rubygems, :user_id
  end

  def self.down
    add_column :rubygems, :user_id, :integer
  end
end
