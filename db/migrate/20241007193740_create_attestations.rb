class CreateAttestations < ActiveRecord::Migration[7.2]
  def change
    create_table :attestations do |t|
      t.belongs_to :version, null: false, foreign_key: true
      t.jsonb :body
      t.string :media_type

      t.timestamps
    end
  end
end
