class ChangeApiKeyUserIdToNull < ActiveRecord::Migration[7.0]
  def change
    change_column_null :api_keys, :user_id, true
  end
end
