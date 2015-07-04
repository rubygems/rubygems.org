class AddVersionHistoryIndexes < ActiveRecord::Migration
  def up
    add_index :version_histories, [:version_id, :day], unique: true
  end

  def down
    remove_index :version_histories,column: [:version_id, :day]
  end
end
