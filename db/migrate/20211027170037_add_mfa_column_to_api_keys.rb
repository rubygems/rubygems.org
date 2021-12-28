class AddMfaColumnToApiKeys < ActiveRecord::Migration[6.1]
  def change
    add_column :api_keys, :mfa, :boolean, default: false, null: false
  end
end
