class AddApiKeyToVersions < ActiveRecord::Migration[7.0]
  def change
    add_reference :versions, :pusher_api_key, null: true, foreign_key: { to_table: :api_keys }
  end
end
