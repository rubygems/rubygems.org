# frozen_string_literal: true

class CreateOrganizationDomains < ActiveRecord::Migration[8.1]
  def change
    create_table :organization_domains do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :domain, null: false
      t.string :token, null: false
      t.datetime :verified_at
      t.datetime :last_checked_at
      t.string :last_check_result

      t.timestamps

      t.check_constraint "domain = lower(domain)", name: "organization_domains_domain_lowercase"
      t.index :token, unique: true
      t.index %i[organization_id domain], unique: true
      t.index :domain, unique: true, where: "verified_at IS NOT NULL",
        name: "index_organization_domains_on_domain_verified"
    end
  end
end
