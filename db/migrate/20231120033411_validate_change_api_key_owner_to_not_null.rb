class ValidateChangeApiKeyOwnerToNotNull < ActiveRecord::Migration[7.0]
  def change
    validate_check_constraint :api_keys, name: "api_keys_owner_id_null"
    validate_check_constraint :api_keys, name: "api_keys_owner_type_null"
  end
end
