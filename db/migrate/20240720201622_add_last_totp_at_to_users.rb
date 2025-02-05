class AddLastTotpAtToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :last_totp_at, :timestamp, null: true
  end
end
