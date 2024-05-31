class CreateLinkVerifications < ActiveRecord::Migration[7.0]
  def change
    create_table :link_verifications do |t|
      t.references :linkable, polymorphic: true, null: false
      t.string :uri, null: false
      t.datetime :last_verified_at, null: true
      t.datetime :last_failure_at, null: true
      t.integer :failures_since_last_verification, default: 0

      t.timestamps

      t.index %w[linkable_id linkable_type uri], name: "index_link_verifications_on_linkable_and_uri"
    end
  end
end
