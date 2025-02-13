class CreateOIDCTrustedPublisherBuildkite < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    create_table :oidc_trusted_publisher_buildkites do |t|
      t.string :organization_slug, null: false
      t.string :pipeline_slug, null: false

      t.timestamps
    end

    add_index :oidc_trusted_publisher_buildkites,
      %i[organization_slug pipeline_slug],
      unique: true, name: "index_oidc_trusted_publisher_buildkite_claims", algorithm: :concurrently
  end
end
