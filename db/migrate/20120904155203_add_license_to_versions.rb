class AddLicenseToVersions < ActiveRecord::Migration
  def change
    add_column :versions, :licenses, :string
  end
end
