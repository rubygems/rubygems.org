class AddLastOtpAtToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :last_otp_at, :datetime
  end
end
