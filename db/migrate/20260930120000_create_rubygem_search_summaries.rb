# frozen_string_literal: true

class CreateRubygemSearchSummaries < ActiveRecord::Migration[8.1]
  def change
    create_table :rubygem_search_summaries do |t|
      t.references :rubygem, null: false, foreign_key: { on_delete: :cascade }, index: { unique: true }
      t.text :summary
      t.virtual :summary_tsv, type: :tsvector, as: "to_tsvector('english', coalesce(summary, ''))", stored: true
      t.timestamps
    end

    add_index :rubygem_search_summaries, :summary_tsv, using: :gin
  end
end
