# frozen_string_literal: true

class RemoveDuplicateOrganizationInvitesIndex < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    # Keep the index created by the polymorphic reference.
    unless index_exists?(:organization_invites, %i[invitable_type invitable_id], name: :index_organization_invites_on_invitable, valid: true)
      raise ActiveRecord::MigrationError, "The retained organization invites index must exist and be valid"
    end

    remove_index :organization_invites, name: :index_organization_invites_on_invitable_type_and_invitable_id,
      algorithm: :concurrently, if_exists: true
  end

  def down
    lock_timeout = select_value("SHOW lock_timeout")
    begin
      safety_assured { execute "SET lock_timeout = 0" }

      if index_exists?(:organization_invites, name: :index_organization_invites_on_invitable_type_and_invitable_id, valid: false)
        remove_index :organization_invites, name: :index_organization_invites_on_invitable_type_and_invitable_id, algorithm: :concurrently
      end

      add_index :organization_invites, %i[invitable_type invitable_id],
        name: :index_organization_invites_on_invitable_type_and_invitable_id,
        algorithm: :concurrently,
        if_not_exists: true
    ensure
      safety_assured { execute "SET lock_timeout = #{connection.quote(lock_timeout)}" }
    end
  end
end
