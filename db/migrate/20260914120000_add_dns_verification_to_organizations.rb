# frozen_string_literal: true

class AddDnsVerificationToOrganizations < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    # Adding nullable columns with no default is safe; bulk takes the table
    # lock once instead of four times. Strong Migrations cannot inspect
    # change_table blocks, hence safety_assured.
    safety_assured do
      change_table :organizations, bulk: true do |t|
        t.column :domain, :string
        t.column :dns_verification_token, :string
        t.column :dns_verified_at, :datetime
        t.column :dns_last_checked_at, :datetime
      end
    end

    # The sweep selects organizations that have claimed a domain, which is a
    # small fraction of the table.
    add_index :organizations, :domain, where: "domain IS NOT NULL", algorithm: :concurrently
  end
end
