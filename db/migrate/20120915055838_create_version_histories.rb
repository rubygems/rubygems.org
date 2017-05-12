class CreateVersionHistories < ActiveRecord::Migration[4.2]
  def change
    create_table :version_histories do |t|
      t.integer :version_id
      t.date :day
      t.integer :count

      t.timestamps
    end
  end
end
