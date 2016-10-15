class RemoveVersionHistory < ActiveRecord::Migration
  def up
    drop_table :version_histories, force: :cascade
  end

  def down
    create_table :version_histories do |t|
      t.integer :version_id
      t.date :day
      t.integer :count
    end

    add_index :version_histories, [:version_id, :day], unique: true
  end
end
