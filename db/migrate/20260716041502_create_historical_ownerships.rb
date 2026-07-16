# frozen_string_literal: true

class CreateHistoricalOwnerships < ActiveRecord::Migration[8.1]
  def change
    create_table :historical_ownerships do |t|
      t.references :rubygem, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :role, null: false
      t.datetime :first_owned_at, null: false
      t.datetime :removed_at

      t.timestamps
    end

    add_index :historical_ownerships, %i[rubygem_id user_id]
  end
end
