class AddVulnerableToVersions < ActiveRecord::Migration[5.0]
  def change
    add_column :versions, :vulnerable, :boolean, default: false, null: false
  end
end
