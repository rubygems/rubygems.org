# frozen_string_literal: true

class CreateTeams < ActiveRecord::Migration[8.1]
  def change
    create_table :organization_teams do |t|
      t.string :handle, null: false
      t.string :name, null: false
      t.references :organization, null: false, foreign_key: true
      t.boolean :default, null: false, default: false

      t.timestamps
    end
  end
end
