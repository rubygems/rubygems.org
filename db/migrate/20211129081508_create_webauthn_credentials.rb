class CreateWebauthnCredentials < ActiveRecord::Migration[6.1]
  def change
    create_table :webauthn_credentials do |t|
      t.references :user, null: false, foreign_key: true
      t.string :external_id, null: false
      t.string :public_key, null: false
      t.string :nickname, null: false
      t.bigint :sign_count, default: 0, null: false

      t.timestamps

      t.index :external_id, unique: true
    end
  end
end
