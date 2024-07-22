class ValidateNonNullConstraintToApiKeyScopes < ActiveRecord::Migration[7.1]
  def change
    validate_check_constraint :api_keys, name: "api_keys_scopes_null"
  end
end
