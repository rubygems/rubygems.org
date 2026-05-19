# frozen_string_literal: true

class AddInfoChecksumV4ToVersions < ActiveRecord::Migration[7.2]
  def change
    safety_assured do
      change_table :versions, bulk: true do |t|
        t.string :info_checksum_v4
        t.string :yanked_info_checksum_v4
      end
    end
  end
end
