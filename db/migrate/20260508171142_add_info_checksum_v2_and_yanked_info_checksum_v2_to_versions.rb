# frozen_string_literal: true

class AddInfoChecksumV2AndYankedInfoChecksumV2ToVersions < ActiveRecord::Migration[8.1]
  def change
    add_column :versions, :info_checksum_v2, :string
    add_column :versions, :yanked_info_checksum_v2, :string
  end
end
