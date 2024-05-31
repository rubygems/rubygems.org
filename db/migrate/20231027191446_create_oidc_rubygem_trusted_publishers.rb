class CreateOIDCRubygemTrustedPublishers < ActiveRecord::Migration[7.0]
  def change
    create_table :oidc_rubygem_trusted_publishers do |t|
      t.references :rubygem, null: false, foreign_key: true
      t.references :trusted_publisher, polymorphic: true, null: false

      t.timestamps
    end

    add_index :oidc_rubygem_trusted_publishers,
      %i[rubygem_id trusted_publisher_id trusted_publisher_type],
      unique: true, name: "index_oidc_rubygem_trusted_publishers_unique"
  end
end
