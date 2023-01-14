class AddWebauthIdToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :webauthn_id, :string
  end
end
