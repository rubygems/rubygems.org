class ChangeSignCountToBigint < ActiveRecord::Migration[5.2]
  def change
    change_column :webauthn_credentials, :sign_count, :bigint
  end
end
