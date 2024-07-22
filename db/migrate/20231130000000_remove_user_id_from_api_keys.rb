class RemoveUserIdFromApiKeys < ActiveRecord::Migration[7.0]
  def change
    safety_assured { remove_column :api_keys, :user_id, :integer }
  end
end
