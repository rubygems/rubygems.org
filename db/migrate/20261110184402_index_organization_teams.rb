# frozen_string_literal: true

class IndexOrganizationTeams < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :teams, "organization_id, LOWER(name)",
      unique: true,
      name: "index_organization_team_name_on_organizations",
      algorithm: :concurrently
  end
end
