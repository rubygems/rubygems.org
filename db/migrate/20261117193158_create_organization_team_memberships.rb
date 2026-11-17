# frozen_string_literal: true

class CreateOrganizationTeamMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :organization_team_memberships do |t|
      t.references :organization_team, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.references :membership, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps
    end

    add_index :organization_team_memberships, %i[organization_team_id membership_id], unique: true,
      name: "index_organization_team_memberships_on_team_and_membership"
  end
end
