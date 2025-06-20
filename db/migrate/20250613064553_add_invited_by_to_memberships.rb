class AddInvitedByToMemberships < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_reference :memberships, :invited_by, null: true, index: { algorithm: :concurrently }
  end
end
