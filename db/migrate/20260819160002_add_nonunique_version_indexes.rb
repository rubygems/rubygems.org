# frozen_string_literal: true

class AddNonuniqueVersionIndexes < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    add_index :versions,
      %i[rubygem_id number platform],
      name: "index_versions_number_platform",
      algorithm: :concurrently,
      if_not_exists: true

    add_index :versions,
      %i[canonical_number rubygem_id platform],
      name: "index_versions_canonical_platform",
      algorithm: :concurrently,
      if_not_exists: true
  end

  def down
    remove_index :versions,
      name: "index_versions_canonical_platform",
      algorithm: :concurrently,
      if_exists: true

    remove_index :versions,
      name: "index_versions_number_platform",
      algorithm: :concurrently,
      if_exists: true
  end
end
