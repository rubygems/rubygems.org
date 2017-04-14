class AddRememberTokenExpiresAt < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :remember_token_expires_at, :datetime
  end
end
