class AddOwnerToApiKeys < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_reference :api_keys, :owner, polymorphic: true, null: true, index: { algorithm: :concurrently }
  end
end
