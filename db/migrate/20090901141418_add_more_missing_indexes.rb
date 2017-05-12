class AddMoreMissingIndexes < ActiveRecord::Migration[4.2]
  def self.up
    add_index 'subscriptions', 'rubygem_id'
    add_index 'subscriptions', 'user_id'
    add_index 'dependencies', 'version_id'
  end

  def self.down
    remove_index 'subscriptions', 'rubygem_id'
    remove_index 'subscriptions', 'user_id'
    remove_index 'dependencies', 'version_id'
  end
end
