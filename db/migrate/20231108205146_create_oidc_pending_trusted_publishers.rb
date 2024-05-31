class CreateOIDCPendingTrustedPublishers < ActiveRecord::Migration[7.0]
  def change
    create_table :oidc_pending_trusted_publishers do |t|
      t.string :rubygem_name
      t.references :user, null: false, foreign_key: true
      t.references :trusted_publisher, null: false, polymorphic: true
      t.timestamp :expires_at, null: false

      t.timestamps
    end
  end
end
