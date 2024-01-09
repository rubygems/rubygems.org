class AddVersionHistoryIndexes < ActiveRecord::Migration[4.2]
  def up
    add_index :version_histories, %i[version_id day], unique: true
  end

  def down
    remove_index :version_histories, column: %i[version_id day]
  end
end
