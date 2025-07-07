class CreateOrganizationInvite < ActiveRecord::Migration[8.0]
  def change
    create_table :organization_invites do |t|
      t.references :user, null: false, foreign_key: { to_table: :users }
      t.references :invitable, polymorphic: true, null: false
      t.string :role, null: true

      t.timestamps
    end

    add_index :organization_invites, %i[invitable_type invitable_id]
  end
end
