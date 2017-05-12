class RemoveUserIdFromRubygems < ActiveRecord::Migration[4.2]
  def self.up
    remove_column :rubygems, :user_id
  end

  def self.down
    add_column :rubygems, :user_id, :integer
  end
end
