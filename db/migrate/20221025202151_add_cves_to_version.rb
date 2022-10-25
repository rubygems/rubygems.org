class AddCvesToVersion < ActiveRecord::Migration[7.0]
  def change
    add_column :versions, :cves, :string
  end
end
