class AddYankedInfoChecksumToVersions < ActiveRecord::Migration
  def change
    add_column :versions, :yanked_info_checksum, :string, default: nil
  end
end
