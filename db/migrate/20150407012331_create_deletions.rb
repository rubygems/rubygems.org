class CreateDeletions < ActiveRecord::Migration[4.2]
  def change
    create_table :deletions do |t|
      t.belongs_to :user, index: true
      t.string :rubygem
      t.string :number
      t.string :platform

      t.timestamps null: false
    end
  end
end
