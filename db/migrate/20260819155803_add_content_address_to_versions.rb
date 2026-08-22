# frozen_string_literal: true

class AddContentAddressToVersions < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    add_column :versions, :content_address, :string, if_not_exists: true

    add_index :versions,
      %i[rubygem_id number content_address],
      unique: true,
      where: "content_address IS NOT NULL",
      name: "index_versions_number_content_address",
      algorithm: :concurrently,
      if_not_exists: true
  end

  def down
    remove_index :versions,
      name: "index_versions_number_content_address",
      algorithm: :concurrently,
      if_exists: true

    remove_column :versions, :content_address, if_exists: true
  end
end
