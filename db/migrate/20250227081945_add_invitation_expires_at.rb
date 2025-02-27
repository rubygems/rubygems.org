class AddInvitationExpiresAt < ActiveRecord::Migration[8.0]
  def change
    add_column :memberships, :invitation_expires_at, :datetime
  end
end
