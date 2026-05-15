# frozen_string_literal: true

class AddInfoChecksumV2AndYankedInfoChecksumV2ToVersions < ActiveRecord::Migration[8.1]
  def change
    change_table :versions, bulk: true do |t|
      t.string :info_checksum_v2
      t.string :yanked_info_checksum_v2
    end
  end
end
