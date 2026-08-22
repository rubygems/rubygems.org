# frozen_string_literal: true

class RemoveOldVersionUniqueIndexes < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    remove_index :versions,
      name: "index_versions_on_canonical_number_and_rubygem_id_and_platform",
      algorithm: :concurrently,
      if_exists: true

    remove_index :versions,
      name: "index_versions_on_rubygem_id_and_number_and_platform",
      algorithm: :concurrently,
      if_exists: true
  end

  # To revert: remove all content-addressable (ruby_abi) variants first —
  # recreating these full uniques fails with PG::UniqueViolation once fat and
  # skinny rows coexist at the same (gem, number, platform). Irreversible
  # after any content-addressable push has landed.
  def down
    add_index :versions,
      %i[canonical_number rubygem_id platform],
      unique: true,
      name: "index_versions_on_canonical_number_and_rubygem_id_and_platform",
      algorithm: :concurrently,
      if_not_exists: true

    add_index :versions,
      %i[rubygem_id number platform],
      unique: true,
      name: "index_versions_on_rubygem_id_and_number_and_platform",
      algorithm: :concurrently,
      if_not_exists: true
  end
end
