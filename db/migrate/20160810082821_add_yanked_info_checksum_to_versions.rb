# frozen_string_literal: true

class AddYankedInfoChecksumToVersions < ActiveRecord::Migration[4.2]
  def change
    add_column :versions, :yanked_info_checksum, :string, default: nil
  end
end
