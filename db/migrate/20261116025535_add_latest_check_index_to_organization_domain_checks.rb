# frozen_string_literal: true

class AddLatestCheckIndexToOrganizationDomainChecks < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  # Serves OrganizationDomainCheck.latest_by_domain_id (DISTINCT ON ordering) and,
  # via its leading column, the foreign key lookups the single-column index covered.
  def change
    add_index :organization_domain_checks, %i[organization_domain_id checked_at id],
      order: { checked_at: :desc, id: :desc }, name: :index_organization_domain_checks_on_domain_latest, algorithm: :concurrently
    remove_index :organization_domain_checks, :organization_domain_id,
      name: :index_organization_domain_checks_on_organization_domain_id, algorithm: :concurrently
  end
end
