class AddIndexToLowercaseEmail < ActiveRecord::Migration[5.2]
  def up
    add_index "users", "lower(email) varchar_pattern_ops", name: "index_users_on_lower_email"
  end

  def down
    remove_index "users", name: "index_users_on_lower_email"
  end
end
