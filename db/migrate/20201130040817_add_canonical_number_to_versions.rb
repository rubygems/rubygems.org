class AddCanonicalNumberToVersions < ActiveRecord::Migration[6.0]
  def change
    add_column :versions, :canonical_number, :string
  end
end
