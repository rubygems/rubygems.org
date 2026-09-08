# frozen_string_literal: true

class CreateApiKeyOrganizationScopes < ActiveRecord::Migration[8.1]
  def change
    create_table :api_key_organization_scopes do |t|
      t.references :api_key, null: false, index: { unique: true },
        foreign_key: { to_table: :api_keys, name: "api_key_organization_scopes_api_key_id_fk" }
      t.references :membership, null: false, foreign_key: true
      t.timestamps
    end

    add_column :api_keys, :soft_deleted_organization_name, :string
  end
end
