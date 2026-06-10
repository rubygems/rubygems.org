# frozen_string_literal: true

class RemoveCompactIndexV1ChecksumsFromVersions < ActiveRecord::Migration[8.1]
  def change
    remove_column :versions, :info_checksum, :string
    remove_column :versions, :yanked_info_checksum, :string
  end
end
