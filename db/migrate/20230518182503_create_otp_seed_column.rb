class CreateOtpSeedColumn < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :otp_seed, :string
  end
end
