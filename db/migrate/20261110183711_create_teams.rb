# frozen_string_literal: true

class CreateTeams < ActiveRecord::Migration[8.1]
  def change
    create_table :organization_teams do |t|
      t.string :name, null: false
      t.references :organization, foreign_key: true

      t.timestamps
    end

    add_index :teams, "organization_id, LOWER(name)", unique: true, name: "index_organization_team_name_on_organizations"
  end
end
