class AddNonNullConstraintToApiKeyScopes < ActiveRecord::Migration[7.1]
  def change
    add_check_constraint :api_keys, "scopes IS NOT NULL", name: "api_keys_scopes_null", validate: false
  end
end
