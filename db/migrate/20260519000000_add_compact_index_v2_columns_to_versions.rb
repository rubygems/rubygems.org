# frozen_string_literal: true

class AddCompactIndexV2ColumnsToVersions < ActiveRecord::Migration[7.1]
  def change
    add_column :versions, :info_checksum_v2, :string
    add_column :versions, :yanked_info_checksum_v2, :string
  end
end
