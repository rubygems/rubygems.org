class CreateAdoptions < ActiveRecord::Migration[5.2]
  def change
    create_table :adoptions do |t|
      t.references :user, foreign_key: true
      t.references :rubygem, foreign_key: true
      t.string :note
      t.integer :status, null: false
    end
  end
end
