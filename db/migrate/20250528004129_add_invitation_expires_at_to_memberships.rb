class AddInvitationExpiresAtToMemberships < ActiveRecord::Migration[8.0]
  def change
    add_column :memberships, :invitation_expires_at, :datetime, null: true
  end
end
