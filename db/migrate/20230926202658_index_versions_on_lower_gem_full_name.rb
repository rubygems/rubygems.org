class IndexVersionsOnLowerGemFullName < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_index :versions, "lower((gem_full_name)::text)", name: "index_versions_on_lower_gem_full_name", algorithm: :concurrently
  end
end
