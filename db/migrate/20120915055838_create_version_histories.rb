class CreateVersionHistories < ActiveRecord::Migration
  def change
    create_table :version_histories do |t|
      t.integer :version_id
      t.date :day
      t.integer :count

      t.timestamps
    end
  end
end
