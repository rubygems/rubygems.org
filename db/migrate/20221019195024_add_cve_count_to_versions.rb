class AddCveCountToVersions < ActiveRecord::Migration[7.0]
  def change
    add_column :versions, :cve_count, :integer
  end
end
