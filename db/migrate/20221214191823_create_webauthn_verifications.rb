class CreateWebauthnVerifications < ActiveRecord::Migration[7.0]
  def change
    create_table :webauthn_verifications do |t|
      t.string :path_token, limit: 128
      t.datetime :path_token_expires_at
      t.string :otp
      t.datetime :otp_expires_at
      t.references :user, null: false, index: { unique: true }, foreign_key: true

      t.timestamps
    end
  end
end
