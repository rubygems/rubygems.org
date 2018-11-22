class RemoveUsersLastOtpAt < ActiveRecord::Migration[5.1]
  def change
    remove_column :users, :last_otp_at
  end
end
