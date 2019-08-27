class AddWebauthnHandleToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :webauthn_handle, :string
  end
end
