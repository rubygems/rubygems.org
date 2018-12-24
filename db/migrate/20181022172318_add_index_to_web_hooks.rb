class AddIndexToWebHooks < ActiveRecord::Migration[5.2]
  def change
    add_index :web_hooks, [:user_id, :rubygem_id]
  end
end
