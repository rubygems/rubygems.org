class AddLicenseToVersions < ActiveRecord::Migration[4.2]
  def change
    add_column :versions, :licenses, :string
  end
end
