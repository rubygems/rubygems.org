class CreateCredentials < ActiveRecord::Migration[5.2]
  def change
    create_table :credentials do |t|
      t.references :user, foreign_key: true
      t.string :external_id, null: false
      t.text :public_key, null: false

      t.timestamps
    end
  end
end
