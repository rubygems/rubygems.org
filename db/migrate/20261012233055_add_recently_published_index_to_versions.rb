# frozen_string_literal: true

class AddRecentlyPublishedIndexToVersions < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    add_index :versions, %i[rubygem_id created_at],
      order: { created_at: :desc },
      where: "indexed = true",
      algorithm: :concurrently
  end

  def down
    remove_index :versions, name: :index_versions_on_rubygem_id_and_created_at, algorithm: :concurrently
  end
end
