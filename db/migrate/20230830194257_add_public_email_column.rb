class AddPublicEmailColumn < ActiveRecord::Migration[7.0]
  def up
    add_column :users, :public_email, :boolean, default: false, null: false
  end

  def down
    remove_column :users, :public_email
  end
end
