class RemoveUsersLastOtpAt < ActiveRecord::Migration[5.1]
  def change
    remove_column :users, :last_otp_at # rubocop:disable Rails/ReversibleMigration
  end
end
