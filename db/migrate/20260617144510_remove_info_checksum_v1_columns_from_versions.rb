# frozen_string_literal: true

class RemoveInfoChecksumV1ColumnsFromVersions < ActiveRecord::Migration[8.1]
  def change
    safety_assured do
      change_table :versions, bulk: true do |t|
        t.remove :info_checksum, type: :string
        t.remove :yanked_info_checksum, type: :string
      end
    end
  end
end
