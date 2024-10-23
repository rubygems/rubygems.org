class CreateTeams < ActiveRecord::Migration[7.1]
  def change
    create_table :teams do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :name, null: false
      t.string :handle, null: false

      t.index %i[organization_id handle], unique: true
      t.timestamps
    end
  end
end
