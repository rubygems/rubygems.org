class AddSha256ToVersions < ActiveRecord::Migration
  def change
    add_column :versions, :sha256, :string, null: true
  end
end
