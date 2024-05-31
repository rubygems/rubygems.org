class AddOwnershipConfirmation < ActiveRecord::Migration[6.0]
  def change
    change_table(:ownerships, bulk: true) do |t|
      t.datetime :confirmed_at
      t.datetime :token_expires_at
      t.boolean :owner_notifier, default: true, null: false
      t.integer :authorizer_id
      t.index %i[user_id rubygem_id], unique: true
    end
  end
end
