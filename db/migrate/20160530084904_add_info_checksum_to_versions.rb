class AddInfoChecksumToVersions < ActiveRecord::Migration[4.2]
  def change
    add_column :versions, :info_checksum, :string
  end
end
