# frozen_string_literal: true

class IndexOrganizationTeams < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  INDEX_NAME = "index_organization_team_handle_on_organizations"

  def up
    add_index :organization_teams, "organization_id, LOWER(handle)",
      unique: true,
      name: INDEX_NAME,
      algorithm: :concurrently,
      if_not_exists: true
  end

  def down
    remove_index :organization_teams,
      name: INDEX_NAME,
      algorithm: :concurrently,
      if_exists: true
  end
end
