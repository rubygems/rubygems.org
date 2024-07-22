class RemoveUnneededIndexes < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    # covered by index_oidc_rubygem_trusted_publishers_unique
    remove_index :oidc_rubygem_trusted_publishers, name: "index_oidc_rubygem_trusted_publishers_on_rubygem_id", column: :rubygem_id,
      algorithm: :concurrently

    # covered by index_ownerships_on_user_id_and_rubygem_id
    remove_index :ownerships, name: "index_ownerships_on_user_id", column: :user_id, algorithm: :concurrently

    # covered by index_versions_on_indexed_and_yanked_at
    remove_index :versions, name: "index_versions_on_indexed", column: :indexed, algorithm: :concurrently

    # covered by index_versions_on_rubygem_id_and_number_and_platform
    remove_index :versions, name: "index_versions_on_rubygem_id", column: :rubygem_id, algorithm: :concurrently
  end
end
