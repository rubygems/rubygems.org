class ChangeUsersHideEmailDefault < ActiveRecord::Migration[6.1]
  def change
    change_column_default :users, :hide_email, from: nil, to: true
  end
end
