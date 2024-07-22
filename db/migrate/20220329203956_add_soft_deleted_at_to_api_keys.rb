class AddSoftDeletedAtToApiKeys < ActiveRecord::Migration[7.0]
  def change
    change_table(:api_keys, bulk: true) do |t|
      t.datetime :soft_deleted_at
      t.string :soft_deleted_rubygem_name
    end
  end
end
