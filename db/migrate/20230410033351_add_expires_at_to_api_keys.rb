class AddExpiresAtToApiKeys < ActiveRecord::Migration[7.0]
  def change
    add_column :api_keys, :expires_at, :timestamp
  end
end
