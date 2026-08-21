# frozen_string_literal: true

class CreatePrefixReservation < ActiveRecord::Migration[8.1]
  def change
    create_table :prefix_reservations do |t|
      t.string :prefix, null: false
      t.references :organization

      t.timestamps
    end

    add_index :prefix_reservations, :prefix, unique: true
  end
end
