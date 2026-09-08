# frozen_string_literal: true

class AddOrganizationToOIDCPendingTrustedPublishers < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_reference :oidc_pending_trusted_publishers, :organization, null: true, index: { algorithm: :concurrently }
    add_foreign_key :oidc_pending_trusted_publishers, :organizations, column: :organization_id, on_delete: :nullify, validate: false
  end
end
