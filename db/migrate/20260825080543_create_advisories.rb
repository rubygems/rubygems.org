# frozen_string_literal: true

class CreateAdvisories < ActiveRecord::Migration[8.1]
  def change
    create_table :advisories do |t|
      t.string :type, null: false
      t.string :identifier, null: false
      t.string :rubygem_name, null: false
      t.string :aliases, null: false, array: true, default: []
      t.text :summary, null: false
      t.string :severity
      t.string :url, null: false
      t.datetime :published_at
      t.datetime :modified_at, null: false
      t.datetime :withdrawn_at
      t.jsonb :ranges, null: false, default: []
      t.jsonb :payload, null: false, default: {}

      t.timestamps
    end

    add_index :advisories, %i[type identifier rubygem_name], unique: true
    add_index :advisories, :rubygem_name
  end
end
