class AddSoftDeletedAtToApiKeys < ActiveRecord::Migration[7.0]
  def change
    add_column :api_keys, :soft_deleted_at, :datetime
  end
end
