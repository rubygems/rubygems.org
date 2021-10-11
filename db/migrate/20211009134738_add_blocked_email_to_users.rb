class AddBlockedEmailToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :blocked_email, :string
  end
end
