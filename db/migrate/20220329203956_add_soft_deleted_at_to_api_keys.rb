class AddSoftDeletedAtToApiKeys < ActiveRecord::Migration[7.0]
  def change
    add_column :api_keys, :soft_deleted_at, :datetime  # rubocop:disable Rails/BulkChangeTable
    add_column :api_keys, :soft_deleted_rubygem_name, :string
  end
end
