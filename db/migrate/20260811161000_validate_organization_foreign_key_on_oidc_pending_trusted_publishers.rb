# frozen_string_literal: true

class ValidateOrganizationForeignKeyOnOIDCPendingTrustedPublishers < ActiveRecord::Migration[8.1]
  def change
    validate_foreign_key :oidc_pending_trusted_publishers, :organizations
  end
end
