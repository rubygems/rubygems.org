class AddInfoChecksumToVersions < ActiveRecord::Migration
  def change
    add_column :versions, :info_checksum, :string
  end
end
