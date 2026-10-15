# frozen_string_literal: true

class CreateSponsors < ActiveRecord::Migration[8.1]
  def change
    create_table :sponsors do |t|
      t.string :name, null: false
      t.string :website_url
      t.integer :tier, null: false
      t.boolean :anonymous, null: false, default: false
      t.boolean :show_in_footer, null: false, default: false
      t.integer :position, null: false, default: 0

      t.timestamps
    end
  end
end
