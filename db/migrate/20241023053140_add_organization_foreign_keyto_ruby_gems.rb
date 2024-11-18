class AddOrganizationForeignKeytoRubyGems < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    add_reference :rubygems, :organization, null: true, index: { algorithm: :concurrently }
    add_foreign_key :rubygems, :organizations, column: :organization_id, on_delete: :nullify, validate: false
  end
end
