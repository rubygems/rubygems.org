# frozen_string_literal: true

class CreateOrganizationDomainChecks < ActiveRecord::Migration[8.1]
  def change
    create_table :organization_domain_checks do |t|
      t.references :organization_domain, null: false, foreign_key: true
      t.datetime :checked_at, null: false
      t.string :result, null: false
      t.string :outcome, null: false
      t.text :message

      t.timestamps
    end
  end
end
