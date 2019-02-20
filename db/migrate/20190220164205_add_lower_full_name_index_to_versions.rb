class AddLowerFullNameIndexToVersions < ActiveRecord::Migration[5.2]
  def change
    add_index :versions, 'lower(full_name)'
  end
end
