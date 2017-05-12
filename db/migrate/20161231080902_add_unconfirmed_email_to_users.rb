class AddUnconfirmedEmailToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :unconfirmed_email, :string
  end
end
