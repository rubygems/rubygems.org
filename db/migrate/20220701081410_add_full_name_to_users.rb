class AddFullNameToUsers < ActiveRecord::Migration[7.0]
  def up
    add_column :users, :full_name, :string
  end

  def down
    remove_column :users, :full_name, :string
  end
end
