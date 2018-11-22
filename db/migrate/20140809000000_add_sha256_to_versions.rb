class AddSha256ToVersions < ActiveRecord::Migration[4.2]
  def change
    add_column :versions, :sha256, :string, null: true
  end
end
