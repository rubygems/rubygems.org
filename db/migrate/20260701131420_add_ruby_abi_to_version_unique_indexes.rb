# frozen_string_literal: true

class AddRubyAbiToVersionUniqueIndexes < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    remove_index :versions,
      name: "index_versions_on_canonical_number_and_rubygem_id_and_platform",
      algorithm: :concurrently

    remove_index :versions,
      name: "index_versions_on_rubygem_id_and_number_and_platform",
      algorithm: :concurrently

    add_index :versions,
      %i[canonical_number rubygem_id platform],
      unique: true,
      where: "ruby_abi IS NULL",
      name: "index_versions_on_canonical_number_rubygem_id_platform_no_abi",
      algorithm: :concurrently

    add_index :versions,
      %i[canonical_number rubygem_id platform ruby_abi],
      unique: true,
      where: "ruby_abi IS NOT NULL",
      name: "index_versions_on_canonical_number_rubygem_id_platform_abi",
      algorithm: :concurrently

    add_index :versions,
      %i[rubygem_id number platform],
      unique: true,
      where: "ruby_abi IS NULL",
      name: "index_versions_on_rubygem_id_number_platform_no_abi",
      algorithm: :concurrently

    add_index :versions,
      %i[rubygem_id number platform ruby_abi],
      unique: true,
      where: "ruby_abi IS NOT NULL",
      name: "index_versions_on_rubygem_id_number_platform_abi",
      algorithm: :concurrently
  end

  def down
    remove_index :versions,
      name: "index_versions_on_canonical_number_rubygem_id_platform_no_abi",
      algorithm: :concurrently

    remove_index :versions,
      name: "index_versions_on_canonical_number_rubygem_id_platform_abi",
      algorithm: :concurrently

    remove_index :versions,
      name: "index_versions_on_rubygem_id_number_platform_no_abi",
      algorithm: :concurrently

    remove_index :versions,
      name: "index_versions_on_rubygem_id_number_platform_abi",
      algorithm: :concurrently

    add_index :versions,
      %i[canonical_number rubygem_id platform],
      unique: true,
      name: "index_versions_on_canonical_number_and_rubygem_id_and_platform",
      algorithm: :concurrently

    add_index :versions,
      %i[rubygem_id number platform],
      unique: true,
      name: "index_versions_on_rubygem_id_and_number_and_platform",
      algorithm: :concurrently
  end
end
