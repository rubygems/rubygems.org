# frozen_string_literal: true

class CreateTeams < ActiveRecord::Migration[8.1]
  def change
    create_table :organization_teams do |t|
      t.string :name, null: false
      t.references :organization, foreign_key: true
      t.boolean :default, null: false

      t.timestamps
    end
  end
end
