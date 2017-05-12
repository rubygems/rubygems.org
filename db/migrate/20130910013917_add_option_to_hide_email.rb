class AddOptionToHideEmail < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :hide_email, :boolean
  end
end
