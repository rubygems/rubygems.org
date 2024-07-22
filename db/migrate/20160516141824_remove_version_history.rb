class RemoveVersionHistory < ActiveRecord::Migration[4.2]
  def up
    drop_table :version_histories, force: :cascade
  end

  def down
    create_table :version_histories do |t| # rubocop:disable Rails/CreateTableWithTimestamps
      t.integer :version_id
      t.date :day
      t.integer :count
    end

    add_index :version_histories, %i[version_id day], unique: true
  end
end
