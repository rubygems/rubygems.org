class CreateOtpSeedColumn < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :totp_seed, :string
  end
end
