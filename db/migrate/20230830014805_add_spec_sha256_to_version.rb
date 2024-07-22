class AddSpecSha256ToVersion < ActiveRecord::Migration[7.0]
  def change
    add_column :versions, :spec_sha256, :string, limit: 44
  end
end
